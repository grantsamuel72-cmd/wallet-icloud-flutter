import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wallet_cloud_backup/src/crypto/backup_kdf.dart';
import 'package:wallet_cloud_backup/src/crypto/mnemonic_sealer.dart';
import 'package:wallet_cloud_backup/src/domain/backup_file_names.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_file.dart';
import 'package:wallet_cloud_backup/src/domain/exceptions.dart';
import 'package:wallet_cloud_backup/src/domain/wallet_backup.dart';
import 'package:wallet_cloud_backup/src/wallet_cloud_backup_service.dart';
import 'package:wallet_core/wallet_core.dart';

/// One wallet found in the cloud, as shown on a restore screen. Holds no secrets.
class RestorableWallet {
  /// Creates a listing entry.
  const RestorableWallet({
    required this.walletId,
    required this.file,
    this.label,
    this.createdAt,
    this.error,
  });

  /// Wallet identifier to pass to [MnemonicCloudBackup.restoreMnemonic].
  final String walletId;

  /// Cloud file metadata, including iCloud conflict state.
  final CloudBackupFile file;

  /// App-supplied label. Stored in plain text and only authenticated once the
  /// password opens the backup, so do not treat it as trusted before that.
  final String? label;

  /// When the backup was sealed.
  final DateTime? createdAt;

  /// Why this entry cannot be restored with a password, or null when it can.
  final WalletCloudBackupException? error;

  /// Whether [MnemonicCloudBackup.restoreMnemonic] can be attempted.
  bool get isRestorable => error == null;
}

/// Password-protected BIP39 mnemonic backups on top of [WalletCloudBackup].
///
/// The mnemonic is encrypted on the device (Argon2id + AES-256-GCM, see
/// [MnemonicSealer]) and only the ciphertext is uploaded. Wallet Core's
/// high-level API validates mnemonics and checks, after every decrypt, that the
/// phrase still derives the Ethereum address recorded when it was sealed. The
/// full `WalletCoreApi` is not used, so the official Trust Wallet Core SDK is
/// enough on both platforms.
///
/// Key derivation takes roughly 0.2–1.5 s depending on the device and runs on
/// a background isolate. Runtime failures are [WalletCloudBackupException]s;
/// caller mistakes keep their usual types: [StateError] for a disposed
/// [HDWallet] and [ArgumentError] for a BIP39 passphrase Wallet Core rejects.
class MnemonicCloudBackup {
  /// Creates a mnemonic backup service storing files through [cloud].
  ///
  /// [minPasswordLength] counts Unicode code points and cannot be below 8.
  MnemonicCloudBackup(
    WalletCloudBackup cloud, {
    WalletCore? walletCore,
    BackupKdfParameters kdf = BackupKdfParameters.recommended,
    int minPasswordLength = 8,
  }) : this.forTesting(
         cloud,
         walletCore: walletCore,
         kdf: kdf,
         minPasswordLength: minPasswordLength,
       );

  /// Also accepts Argon2id parameters below the production minimum and a
  /// deterministic [random], so tests run fast and reproducibly.
  @visibleForTesting
  MnemonicCloudBackup.forTesting(
    this.cloud, {
    WalletCore? walletCore,
    BackupKdfParameters kdf = BackupKdfParameters.recommended,
    this.minPasswordLength = 8,
    BackupKdfParameters minimumKdf = BackupKdfParameters.minimum,
    Random? random,
  }) : _walletCore = walletCore ?? WalletCore(),
       _sealer = MnemonicSealer(kdf: kdf, minimumKdf: minimumKdf, random: random) {
    if (minPasswordLength < 8) {
      throw ArgumentError.value(minPasswordLength, 'minPasswordLength', 'Must be at least 8.');
    }
  }

  /// Cloud storage used for the sealed files.
  final WalletCloudBackup cloud;

  /// Minimum length of a new backup password, in Unicode code points.
  final int minPasswordLength;

  final WalletCore _walletCore;
  final MnemonicSealer _sealer;

  // BIP39 test vector; checking it proves Wallet Core's native code runs.
  static const String _probeMnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  static const Set<String> _unavailableCodes = <String>{
    'native_library_unavailable',
    'channel-error',
  };

  /// Whether Wallet Core's native library works in this build. Never throws.
  ///
  /// False on an Android ABI that the Wallet Core SDK was not built for, or in
  /// unit tests without a fake platform.
  Future<bool> isWalletCoreAvailable() async {
    try {
      return await _core(() => _walletCore.isValidMnemonic(_probeMnemonic));
    } on WalletCloudBackupException {
      return false;
    }
  }

  /// Encrypts [mnemonic] with [password] on this device and uploads it,
  /// replacing the previous backup of [walletId].
  ///
  /// The uploaded file is read back and compared before this returns. A BIP39
  /// passphrase is never part of the backup. [label] is stored in plain text
  /// for the restore screen; do not put addresses or balances in it.
  ///
  /// Throws [WeakBackupPasswordException], [InvalidMnemonicException],
  /// [WalletCoreUnavailableException] or a cloud error. If the upload
  /// succeeded but the read-back check failed, the [CloudStorageException]
  /// says so: the previous backup may already be replaced, so check with
  /// [verifyPassword] before telling the user nothing changed.
  Future<CloudBackupFile> backupMnemonic({
    required String walletId,
    required String mnemonic,
    required String password,
    String? label,
  }) async {
    final normalizedWalletId = normalizeWalletId(walletId);
    _checkNewPassword(password);
    MnemonicSealer.normalizeLabel(label);
    final phrase = await _validMnemonic(mnemonic);
    final backup = await _sealer.seal(
      walletId: normalizedWalletId,
      mnemonic: phrase,
      ethereumAddress: await _ethereumAddress(phrase),
      password: password,
      label: label,
    );
    final file = await cloud.backup(backup);
    final WalletBackup stored;
    try {
      stored = await cloud.restore(normalizedWalletId);
    } on WalletCloudBackupException catch (error) {
      throw CloudStorageException(_unverifiedUpload, cause: error);
    }
    if (stored.checksum != backup.checksum) {
      throw const CloudStorageException(_unverifiedUpload);
    }
    return file;
  }

  /// Backs up [wallet]'s mnemonic; see [backupMnemonic]. Does not dispose [wallet].
  Future<CloudBackupFile> backupWallet({
    required String walletId,
    required HDWallet wallet,
    required String password,
    String? label,
  }) async {
    _checkNewPassword(password);
    return backupMnemonic(
      walletId: walletId,
      mnemonic: await _core(wallet.getMnemonic),
      password: password,
      label: label,
    );
  }

  /// Lists the wallets in the cloud, newest first, without a password.
  ///
  /// A damaged or foreign file becomes an entry with [RestorableWallet.error]
  /// instead of failing the whole list. Authorization and availability
  /// errors still throw.
  Future<List<RestorableWallet>> listRestorable() async {
    final files = await cloud.list();
    final wallets = <RestorableWallet>[];
    // Each entry needs its own download, so this is the one place where the
    // cost grows with the number of wallets. Describing them in small batches
    // keeps that from becoming a sum of round trips (Drive) or of sync
    // timeouts (iCloud) while still bounding how much runs at once.
    for (var start = 0; start < files.length; start += _describeConcurrency) {
      final batch = files.skip(start).take(_describeConcurrency);
      wallets.addAll(await Future.wait(batch.map(_describe)));
    }
    return List<RestorableWallet>.unmodifiable(wallets);
  }

  // Small enough to stay polite to the provider, large enough that a restore
  // screen does not wait for one round trip per wallet.
  static const int _describeConcurrency = 4;

  /// Reads one cloud file and turns it into a listing entry.
  ///
  /// A damaged or foreign file becomes an entry carrying the error; only
  /// provider-level failures propagate and fail the whole listing.
  Future<RestorableWallet> _describe(CloudBackupFile file) async {
    final walletId = file.walletId!;
    try {
      final backup = await cloud.restore(walletId);
      final header = _sealer.inspect(backup);
      return RestorableWallet(
        walletId: walletId,
        file: file,
        label: header?.label,
        createdAt: backup.createdAt,
        error: header == null
            ? const BackupFormatException('This backup does not contain a sealed mnemonic.')
            : null,
      );
    } on CloudAuthenticationException {
      rethrow;
    } on CloudUnavailableException {
      rethrow;
    } on WalletCloudBackupException catch (error) {
      return RestorableWallet(walletId: walletId, file: file, error: error);
    }
  }

  /// Decrypts [walletId]'s backup and returns its mnemonic.
  ///
  /// Throws [WrongBackupPasswordException] when [password] is wrong and
  /// [BackupIntegrityException] when the file was altered or no longer
  /// derives the wallet it was made from.
  Future<String> restoreMnemonic(String walletId, {required String password}) async =>
      _openAndVerify(await cloud.restore(walletId), password);

  /// Restores [walletId] as a Wallet Core wallet. The caller must dispose it.
  ///
  /// [bip39Passphrase] is the optional "25th word"; it is not in the backup.
  Future<HDWallet> restoreWallet(
    String walletId, {
    required String password,
    String bip39Passphrase = '',
  }) async {
    final mnemonic = await restoreMnemonic(walletId, password: password);
    return _core(() => _walletCore.importWallet(mnemonic: mnemonic, passphrase: bip39Passphrase));
  }

  /// Whether [password] opens [walletId]'s backup, for "do you still remember
  /// your backup password?" reminders.
  ///
  /// Returns false only for a wrong password; a damaged file still throws.
  Future<bool> verifyPassword(String walletId, {required String password}) async {
    final backup = await cloud.restore(walletId);
    try {
      await _sealer.open(backup, password: password);
      return true;
    } on WrongBackupPasswordException {
      return false;
    }
  }

  /// Re-encrypts [walletId]'s backup with [newPassword], keeping its label.
  ///
  /// Nothing is written unless [currentPassword] opens the backup. Earlier
  /// ciphertexts may survive in the provider's version history (Google Drive
  /// revisions, iCloud versions), so anyone who learns the old password can
  /// still open those copies.
  Future<CloudBackupFile> changePassword(
    String walletId, {
    required String currentPassword,
    required String newPassword,
  }) async {
    _checkNewPassword(newPassword);
    final backup = await cloud.restore(walletId);
    final mnemonic = await _openAndVerify(backup, currentPassword);
    return backupMnemonic(
      walletId: walletId,
      mnemonic: mnemonic,
      password: newPassword,
      // Authenticated by the successful open above.
      label: _sealer.inspect(backup)?.label,
    );
  }

  static const String _unverifiedUpload =
      'The backup was uploaded but could not be verified; it may already have replaced the '
      'previous one.';

  /// Decrypts [backup] and checks the phrase still derives the sealed wallet.
  Future<String> _openAndVerify(WalletBackup backup, String password) async {
    final contents = await _sealer.open(backup, password: password);
    if (!await _core(() => _walletCore.isValidMnemonic(contents.mnemonic))) {
      throw const BackupIntegrityException('The restored mnemonic is not a valid BIP39 phrase.');
    }
    if (await _ethereumAddress(contents.mnemonic) != contents.ethereumAddress) {
      throw const BackupIntegrityException(
        'The restored mnemonic does not derive the wallet it was backed up from.',
      );
    }
    return contents.mnemonic;
  }

  void _checkNewPassword(String password) {
    if (password.runes.length < minPasswordLength) {
      throw WeakBackupPasswordException(minPasswordLength);
    }
  }

  /// Returns [mnemonic] normalized the same way Wallet Core imports it.
  Future<String> _validMnemonic(String mnemonic) async {
    final phrase = mnemonic.trim().split(RegExp(r'\s+')).join(' ');
    final bool valid;
    try {
      valid = await _core(() => _walletCore.isValidMnemonic(phrase));
    } on ArgumentError {
      // Wallet Core's own text checks; its message never includes the input.
      throw const InvalidMnemonicException();
    }
    if (!valid) {
      throw const InvalidMnemonicException();
    }
    return phrase;
  }

  /// Ethereum address at Wallet Core's default path, without a BIP39 passphrase.
  Future<String> _ethereumAddress(String mnemonic) async {
    final wallet = await _core(() => _walletCore.importWallet(mnemonic: mnemonic));
    try {
      return await _core(() => wallet.getAddress(CoinType.ethereum));
    } finally {
      try {
        await wallet.dispose();
      } on Exception {
        // Release is best effort; Wallet Core frees the handle with its engine.
      }
    }
  }

  static Future<T> _core<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on WalletCoreException catch (error) {
      if (error.code == 'invalid_mnemonic') {
        throw InvalidMnemonicException(cause: error);
      }
      if (_unavailableCodes.contains(error.code)) {
        throw WalletCoreUnavailableException(
          'Wallet Core is unavailable (${error.code}).',
          cause: error,
        );
      }
      throw WalletCloudBackupException('Wallet Core failed (${error.code}).', cause: error);
    } on MissingPluginException catch (error) {
      throw WalletCoreUnavailableException('Wallet Core is not registered.', cause: error);
    } on UnsupportedError catch (error) {
      throw WalletCoreUnavailableException('Wallet Core is not available here.', cause: error);
    }
  }
}
