import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';
import 'package:wallet_cloud_backup/src/crypto/aes_gcm_backup_cipher.dart';
import 'package:wallet_cloud_backup/src/crypto/backup_kdf.dart';
import 'package:wallet_cloud_backup/src/domain/backup_file_names.dart';
import 'package:wallet_cloud_backup/src/domain/canonical_json.dart';
import 'package:wallet_cloud_backup/src/domain/exceptions.dart';
import 'package:wallet_cloud_backup/src/domain/wallet_backup.dart';

/// Decrypted contents of a mnemonic backup. [toString] never reveals them.
class MnemonicBackupContents {
  /// Creates decrypted contents.
  const MnemonicBackupContents({
    required this.mnemonic,
    required this.ethereumAddress,
    this.tronAddress,
  });

  /// Whitespace-normalized BIP39 phrase.
  final String mnemonic;

  /// Ethereum address at `m/44'/60'/0'/0/0` with an empty BIP39 passphrase,
  /// recorded when sealing so a restore can confirm it rebuilds the same wallet.
  final String ethereumAddress;

  /// TRON address at Wallet Core's default path, if this backup recorded one.
  final String? tronAddress;

  @override
  String toString() => 'MnemonicBackupContents(<redacted>)';
}

/// Non-secret part of a mnemonic backup, readable without the password.
class MnemonicBackupHeader {
  MnemonicBackupHeader._({
    required this.label,
    required this.kdf,
    required this.salt,
    required this.keyCheck,
    required this.payload,
    required this.associatedData,
  });

  /// App-supplied label, stored in plain text.
  final String? label;

  /// Argon2id parameters of this backup.
  final BackupKdfParameters kdf;

  /// Argon2id salt.
  final Uint8List salt;

  /// Password check value derived with the key.
  final Uint8List keyCheck;

  /// Encrypted mnemonic.
  final AesGcmEncryptedPayload payload;

  /// Bytes authenticated together with [payload].
  final Uint8List associatedData;
}

/// Seals a BIP39 mnemonic into a [WalletBackup] with a password.
///
/// Scheme `wallet_cloud_backup.mnemonic.v1`:
/// - Argon2id(password, 16-byte random salt) → 32-byte master key;
/// - HKDF-SHA256(master) → AES-256 key and a 16-byte key-check value, so a
///   wrong password is told apart from a damaged file without weakening the KDF;
/// - AES-256-GCM over the mnemonic and its Ethereum address, plus an optional
///   TRON address, padded to 512
///   bytes so the word count does not leak, with the wallet id, creation time
///   and every header field (label, KDF parameters, key check) as associated data.
///
/// Nothing about the wallet other than the optional label is stored in plain text.
class MnemonicSealer {
  /// Creates a sealer that uses [kdf] for new backups.
  ///
  /// [minimumKdf] and [random] exist for tests: production code keeps the
  /// defaults so weak parameters are never accepted.
  MnemonicSealer({
    this.kdf = BackupKdfParameters.recommended,
    this.minimumKdf = BackupKdfParameters.minimum,
    Random? random,
    AesGcmBackupCipher? cipher,
  }) : _random = random ?? Random.secure(),
       _cipher = cipher ?? AesGcmBackupCipher() {
    if (!kdf.isWithin(minimumKdf, BackupKdfParameters.maximum)) {
      throw ArgumentError.value(kdf, 'kdf', 'Outside the accepted Argon2id range.');
    }
  }

  /// Scheme identifier stored in `encryptedKeystore.scheme`.
  static const String scheme = 'wallet_cloud_backup.mnemonic.v1';

  /// Maximum label length in Unicode code points.
  static const int maxLabelLength = 64;

  static const int _saltLength = 16;
  static const int _keyCheckLength = 16;
  static const int _plaintextBucket = 512;
  static const int _maxCipherTextLength = 4096;
  static const Set<String> _unauthenticatedFields = <String>{'nonce', 'cipherText', 'mac'};

  /// Argon2id parameters for new backups.
  final BackupKdfParameters kdf;

  /// Weakest Argon2id parameters accepted when reading.
  final BackupKdfParameters minimumKdf;

  final Random _random;
  final AesGcmBackupCipher _cipher;

  /// Encrypts [mnemonic] for [walletId]. Nothing leaves the device.
  ///
  /// The result is decrypted once in memory before it is returned.
  Future<WalletBackup> seal({
    required String walletId,
    required String mnemonic,
    required String ethereumAddress,
    String? tronAddress,
    required String password,
    String? label,
    DateTime? createdAt,
  }) async {
    final normalizedWalletId = normalizeWalletId(walletId);
    final normalizedLabel = normalizeLabel(label);
    final sealedAt = (createdAt ?? DateTime.now()).toUtc();
    final salt = Uint8List.fromList(List<int>.generate(_saltLength, (_) => _random.nextInt(256)));
    final keys = await _deriveKeys(password, salt, kdf);
    if (tronAddress != null && tronAddress.isEmpty) {
      throw const BackupFormatException('tronAddress must not be empty.');
    }
    final plaintext = _encodePlaintext(mnemonic, ethereumAddress, tronAddress);
    try {
      final header = <String, Object?>{
        'scheme': scheme,
        'label': ?normalizedLabel,
        'keyCheck': base64Encode(keys.check),
        'keyDerivation': <String, Object?>{
          'algorithm': 'argon2id',
          'version': 19,
          'memoryKiB': kdf.memoryKiB,
          'iterations': kdf.iterations,
          'parallelism': kdf.parallelism,
          'salt': base64Encode(salt),
        },
        'algorithm': 'AES-256-GCM',
      };
      final associatedData = _associatedData(normalizedWalletId, sealedAt, header);
      final key = SecretKeyData(keys.encryption);
      final payload = await _cipher.encrypt(
        plaintext,
        key: key,
        keyDerivation: header['keyDerivation']! as Map<String, Object?>,
        aad: associatedData,
      );
      final roundTrip = await _cipher.decrypt(payload, key: key, aad: associatedData);
      final matches = constantTimeBytesEquality.equals(roundTrip, plaintext);
      roundTrip.fillRange(0, roundTrip.length, 0);
      if (!matches) {
        throw const WalletCloudBackupException('The sealed backup failed its self-check.');
      }
      return WalletBackup.create(
        walletId: normalizedWalletId,
        encryptedKeystore: <String, Object?>{...header, ...payload.toJson()},
        createdAt: sealedAt,
      );
    } finally {
      keys.destroy();
      plaintext.fillRange(0, plaintext.length, 0);
    }
  }

  /// Decrypts [backup] with [password].
  ///
  /// Throws [WrongBackupPasswordException] when the password does not match,
  /// [BackupIntegrityException] when the password matches but the content was
  /// altered, and [BackupFormatException] when [backup] is not a mnemonic
  /// backup or its parameters are out of range.
  Future<MnemonicBackupContents> open(WalletBackup backup, {required String password}) async {
    final header = inspect(backup);
    if (header == null) {
      throw const BackupFormatException('This backup does not contain a sealed mnemonic.');
    }
    final keys = await _deriveKeys(password, header.salt, header.kdf);
    Uint8List? plaintext;
    try {
      if (!constantTimeBytesEquality.equals(keys.check, header.keyCheck)) {
        throw const WrongBackupPasswordException();
      }
      plaintext = await _cipher.decrypt(
        header.payload,
        key: SecretKeyData(keys.encryption),
        aad: header.associatedData,
      );
      return _decodePlaintext(plaintext);
    } finally {
      keys.destroy();
      plaintext?.fillRange(0, plaintext.length, 0);
    }
  }

  /// Returns the header of [backup], or null when it is not a mnemonic backup.
  ///
  /// Throws [BackupFormatException] when it claims to be one but is malformed
  /// or uses Argon2id parameters outside the accepted range. Checked before
  /// any key derivation, so a crafted file cannot exhaust memory.
  MnemonicBackupHeader? inspect(WalletBackup backup) {
    final fields = backup.encryptedKeystore;
    if (fields['scheme'] != scheme) {
      return null;
    }
    final label = fields['label'];
    if (label != null && (label is! String || normalizeLabel(label) != label)) {
      throw const BackupFormatException('Backup label is invalid.');
    }
    final keyCheck = _decodeBase64(fields['keyCheck'], 'keyCheck');
    if (keyCheck.length != _keyCheckLength) {
      throw const BackupFormatException('keyCheck has an invalid length.');
    }
    final derivation = fields['keyDerivation'];
    if (derivation is! Map<String, Object?> ||
        derivation['algorithm'] != 'argon2id' ||
        derivation['version'] != 19) {
      throw const BackupFormatException('Unsupported key derivation.');
    }
    final memoryKiB = derivation['memoryKiB'];
    final iterations = derivation['iterations'];
    final parallelism = derivation['parallelism'];
    if (memoryKiB is! int || iterations is! int || parallelism is! int) {
      throw const BackupFormatException('Argon2id parameters must be integers.');
    }
    final kdf = BackupKdfParameters(
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
    );
    if (!kdf.isWithin(minimumKdf, BackupKdfParameters.maximum)) {
      throw const BackupFormatException('Argon2id parameters are outside the accepted range.');
    }
    final salt = _decodeBase64(derivation['salt'], 'salt');
    if (salt.length < _saltLength || salt.length > 64) {
      throw const BackupFormatException('salt has an invalid length.');
    }
    final payload = AesGcmEncryptedPayload.fromJson(fields);
    if (payload.cipherText.isEmpty || payload.cipherText.length > _maxCipherTextLength) {
      throw const BackupFormatException('cipherText has an invalid length.');
    }
    return MnemonicBackupHeader._(
      label: label as String?,
      kdf: kdf,
      salt: salt,
      keyCheck: keyCheck,
      payload: payload,
      associatedData: _associatedData(backup.walletId, backup.createdAt, <String, Object?>{
        for (final entry in fields.entries)
          if (!_unauthenticatedFields.contains(entry.key)) entry.key: entry.value,
      }),
    );
  }

  /// Trims [label]; returns null when empty.
  ///
  /// Throws [BackupFormatException] for more than [maxLabelLength] code points
  /// or control characters.
  static String? normalizeLabel(String? label) {
    if (label == null) {
      return null;
    }
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.runes.length > maxLabelLength ||
        trimmed.runes.any((rune) => rune < 0x20 || rune == 0x7f) ||
        utf8.decode(utf8.encode(trimmed)) != trimmed) {
      throw const BackupFormatException(
        'label must be at most $maxLabelLength characters without control characters.',
      );
    }
    return trimmed;
  }

  static Future<_DerivedKeys> _deriveKeys(
    String password,
    Uint8List salt,
    BackupKdfParameters parameters,
  ) async {
    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    Uint8List? master;
    try {
      try {
        master = await deriveArgon2idKey(passwordBytes, salt, parameters);
      } catch (error) {
        // Allocation failures or isolate errors; they never contain the password.
        throw WalletCloudBackupException('Key derivation failed.', cause: error);
      }
      return _DerivedKeys(
        encryption: await _hkdf(master, 'wallet_cloud_backup mnemonic v1 encryption', 32),
        check: await _hkdf(master, 'wallet_cloud_backup mnemonic v1 key-check', _keyCheckLength),
      );
    } finally {
      passwordBytes.fillRange(0, passwordBytes.length, 0);
      master?.fillRange(0, master.length, 0);
    }
  }

  static Future<Uint8List> _hkdf(Uint8List master, String info, int length) async {
    final input = Uint8List.fromList(master);
    try {
      final derived = await Hkdf(
        hmac: Hmac.sha256(),
        outputLength: length,
      ).deriveKey(secretKey: SecretKeyData(input), info: utf8.encode(info));
      final bytes = Uint8List.fromList(derived.bytes);
      derived.destroy();
      return bytes;
    } finally {
      input.fillRange(0, input.length, 0);
    }
  }

  static Uint8List _associatedData(
    String walletId,
    DateTime createdAt,
    Map<String, Object?> header,
  ) => Uint8List.fromList(
    utf8.encode(
      canonicalJsonEncode(<String, Object?>{
        'walletId': walletId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'header': header,
      }),
    ),
  );

  static Uint8List _encodePlaintext(String mnemonic, String ethereumAddress, String? tronAddress) {
    final json = utf8.encode(
      canonicalJsonEncode(<String, Object?>{
        'mnemonic': mnemonic,
        'ethereumAddress': ethereumAddress,
        'tronAddress': ?tronAddress,
      }),
    );
    final size = max(
      _plaintextBucket,
      (json.length + _plaintextBucket - 1) ~/ _plaintextBucket * _plaintextBucket,
    );
    final padded = Uint8List(size)
      ..fillRange(0, size, 0x20)
      ..setRange(0, json.length, json);
    json.fillRange(0, json.length, 0);
    return padded;
  }

  static MnemonicBackupContents _decodePlaintext(Uint8List plaintext) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(plaintext));
    } on FormatException {
      // No cause: a FormatException's source would contain the decrypted text.
      throw const BackupIntegrityException('The decrypted backup is malformed.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const BackupIntegrityException('The decrypted backup is malformed.');
    }
    final mnemonic = decoded['mnemonic'];
    final ethereumAddress = decoded['ethereumAddress'];
    final tronAddress = decoded['tronAddress'];
    if (mnemonic is! String ||
        mnemonic.isEmpty ||
        ethereumAddress is! String ||
        (tronAddress != null && (tronAddress is! String || tronAddress.isEmpty))) {
      throw const BackupIntegrityException('The decrypted backup is malformed.');
    }
    return MnemonicBackupContents(
      mnemonic: mnemonic,
      ethereumAddress: ethereumAddress,
      tronAddress: tronAddress as String?,
    );
  }

  static Uint8List _decodeBase64(Object? value, String name) {
    if (value is! String) {
      throw BackupFormatException('$name must be a base64 string.');
    }
    try {
      return base64Decode(value);
    } on FormatException catch (error) {
      throw BackupFormatException('$name is not valid base64.', cause: error);
    }
  }
}

class _DerivedKeys {
  _DerivedKeys({required this.encryption, required this.check});

  final Uint8List encryption;
  final Uint8List check;

  void destroy() {
    encryption.fillRange(0, encryption.length, 0);
    check.fillRange(0, check.length, 0);
  }
}
