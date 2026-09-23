import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:wallet_cloud_backup/src/domain/exceptions.dart';

/// Serialized AES-256-GCM ciphertext.
class AesGcmEncryptedPayload {
  /// Creates a serialized encrypted payload.
  const AesGcmEncryptedPayload({
    required this.nonce,
    required this.cipherText,
    required this.mac,
    required this.keyDerivation,
  });

  /// Random 96-bit nonce.
  final Uint8List nonce;

  /// Encrypted bytes.
  final Uint8List cipherText;

  /// GCM authentication tag.
  final Uint8List mac;

  /// Public parameters needed to re-derive the key from the user's password,
  /// for example `{'algorithm': 'argon2id', 'salt': 'base64...', 'memoryKiB': 65536,
  /// 'iterations': 3, 'parallelism': 1}`.
  ///
  /// Stored in the clear next to the ciphertext so a new device can restore.
  /// It must never contain the password or the key.
  final Map<String, Object?> keyDerivation;

  /// Parses a serialized payload.
  factory AesGcmEncryptedPayload.fromJson(Map<String, Object?> json) {
    Uint8List decodeField(String name) {
      final value = json[name];
      if (value is! String) {
        throw BackupFormatException('$name must be a base64 string.');
      }
      try {
        return base64Decode(value);
      } on FormatException catch (error) {
        throw BackupFormatException('$name is not valid base64.', cause: error);
      }
    }

    if (json['algorithm'] != 'AES-256-GCM') {
      throw BackupFormatException('Unsupported cipher algorithm: ${json['algorithm']}.');
    }
    final nonce = decodeField('nonce');
    final mac = decodeField('mac');
    if (nonce.length != 12 || mac.length != 16) {
      throw const BackupFormatException(
        'AES-GCM nonce or authentication tag has an invalid length.',
      );
    }
    final keyDerivation = json['keyDerivation'];
    if (keyDerivation is! Map<String, Object?> || keyDerivation.isEmpty) {
      throw const BackupFormatException('keyDerivation must be a non-empty object.');
    }
    return AesGcmEncryptedPayload(
      nonce: nonce,
      cipherText: decodeField('cipherText'),
      mac: mac,
      keyDerivation: Map<String, Object?>.unmodifiable(keyDerivation),
    );
  }

  /// Converts this value into a JSON-safe object.
  Map<String, Object?> toJson() => <String, Object?>{
    'algorithm': 'AES-256-GCM',
    'nonce': base64Encode(nonce),
    'cipherText': base64Encode(cipherText),
    'mac': base64Encode(mac),
    'keyDerivation': keyDerivation,
  };
}

/// AES-256-GCM helper that accepts an already derived 32-byte key.
///
/// Derive the key from a user password with Wallet Core, Argon2id, or scrypt.
/// This class deliberately does not turn passwords directly into keys.
class AesGcmBackupCipher {
  /// Creates a cipher using [cryptography], by default the pure-Dart
  /// implementation, which is fast enough for keystore-sized payloads.
  AesGcmBackupCipher({Cryptography? cryptography})
    : _algorithm = (cryptography ?? Cryptography.instance).aesGcm(secretKeyLength: 32);

  final AesGcm _algorithm;

  /// Encrypts [clearText] with a caller-owned 256-bit [key].
  ///
  /// [keyDerivation] records how [key] was derived (algorithm, salt, cost
  /// parameters) and is stored with the ciphertext; see
  /// [AesGcmEncryptedPayload.keyDerivation]. [aad] is authenticated but not
  /// stored; pass the same bytes to [decrypt].
  Future<AesGcmEncryptedPayload> encrypt(
    Uint8List clearText, {
    required SecretKey key,
    required Map<String, Object?> keyDerivation,
    List<int> aad = const <int>[],
  }) async {
    if (keyDerivation.isEmpty) {
      throw ArgumentError.value(keyDerivation, 'keyDerivation', 'Must not be empty.');
    }
    await _validateKey(key);
    final box = await _algorithm.encrypt(clearText, secretKey: key, aad: aad);
    return AesGcmEncryptedPayload(
      nonce: Uint8List.fromList(box.nonce),
      cipherText: Uint8List.fromList(box.cipherText),
      mac: Uint8List.fromList(box.mac.bytes),
      keyDerivation: Map<String, Object?>.unmodifiable(keyDerivation),
    );
  }

  /// Authenticates and decrypts [payload] with [key] and the [aad] used to encrypt it.
  Future<Uint8List> decrypt(
    AesGcmEncryptedPayload payload, {
    required SecretKey key,
    List<int> aad = const <int>[],
  }) async {
    await _validateKey(key);
    try {
      final clearText = await _algorithm.decrypt(
        SecretBox(payload.cipherText, nonce: payload.nonce, mac: Mac(payload.mac)),
        secretKey: key,
        aad: aad,
      );
      return Uint8List.fromList(clearText);
    } on SecretBoxAuthenticationError catch (error) {
      throw BackupIntegrityException('AES-GCM authentication failed.', cause: error);
    }
  }

  static Future<void> _validateKey(SecretKey key) async {
    final bytes = await key.extractBytes();
    if (bytes.length != 32) {
      throw ArgumentError.value(bytes.length, 'key', 'AES-256-GCM requires exactly 32 bytes.');
    }
  }
}
