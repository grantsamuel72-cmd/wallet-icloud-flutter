import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:wallet_cloud_backup/src/data/google_drive_backup_store.dart';
import 'package:wallet_cloud_backup/src/data/icloud_backup_store.dart';
import 'package:wallet_cloud_backup/src/domain/backup_file_names.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_file.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_store.dart';
import 'package:wallet_cloud_backup/src/domain/exceptions.dart';
import 'package:wallet_cloud_backup/src/domain/wallet_backup.dart';

/// iCloud configuration, used on iOS.
class ICloudOptions {
  /// Creates iCloud options.
  const ICloudOptions({
    required this.containerId,
    this.folder = 'WalletBackups',
    this.syncTimeout = const Duration(seconds: 10),
  });

  /// Apple ubiquity container identifier, for example `iCloud.com.example.wallet`.
  final String containerId;

  /// Container-relative folder. Without a `Documents/` prefix it stays hidden from the Files app.
  final String folder;

  /// How long a restore waits for iCloud to sync a backup that is not on this device yet.
  final Duration syncTimeout;
}

/// Wallet backup and restore on the platform's own cloud: iCloud Drive on iOS
/// and the hidden Google Drive `appDataFolder` on Android.
///
/// Each wallet is stored in its own file derived from [WalletBackup.walletId],
/// so backing up one wallet never replaces another.
class WalletCloudBackup {
  /// Selects the backend for the current platform.
  ///
  /// Throws [UnsupportedError] on platforms other than Android and iOS.
  factory WalletCloudBackup({
    required ICloudOptions iCloud,
    GoogleDriveOptions googleDrive = const GoogleDriveOptions(),
    int maxBackupSizeInBytes = defaultMaxBackupSizeInBytes,
  }) {
    final CloudBackupStore store = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => ICloudBackupStore(
        containerId: iCloud.containerId,
        folder: iCloud.folder,
        syncTimeout: iCloud.syncTimeout,
        maxObjectSizeInBytes: maxBackupSizeInBytes,
      ),
      TargetPlatform.android => GoogleDriveBackupStore(
        options: googleDrive,
        maxObjectSizeInBytes: maxBackupSizeInBytes,
      ),
      final platform => throw UnsupportedError(
        'wallet_cloud_backup supports Android and iOS only, not ${platform.name}.',
      ),
    };
    return WalletCloudBackup.withStore(store, maxBackupSizeInBytes: maxBackupSizeInBytes);
  }

  /// Uses a specific [store], for example a fake in tests.
  WalletCloudBackup.withStore(
    this.store, {
    this.maxBackupSizeInBytes = defaultMaxBackupSizeInBytes,
  }) {
    if (maxBackupSizeInBytes <= 0) {
      throw ArgumentError.value(maxBackupSizeInBytes, 'maxBackupSizeInBytes', 'Must be positive.');
    }
  }

  /// Backend in use.
  final CloudBackupStore store;

  /// Maximum accepted serialized backup size. Defaults to 10 MiB.
  final int maxBackupSizeInBytes;

  /// Active provider.
  CloudBackupProvider get provider => store.provider;

  /// Makes the provider ready.
  ///
  /// - iOS: returns whether the user is signed in to iCloud with iCloud Drive
  ///   enabled. [interactive] has no effect.
  /// - Android: with [interactive] false, restores an earlier Drive
  ///   authorization without UI. With [interactive] true, shows the Google
  ///   account picker and consent screen if needed; call it from a user action.
  ///
  /// Returns false when unavailable or cancelled; configuration errors throw
  /// [CloudAuthenticationException]. Other operations call the non-interactive
  /// form automatically.
  Future<bool> connect({bool interactive = false}) => store.connect(interactive: interactive);

  /// Drops the cached access token and signs out of Google on Android; no-op on iOS.
  ///
  /// The Drive grant itself stays in place: the next [connect] (and any
  /// operation) silently obtains a new token for the same account. Keep an
  /// app-level "cloud backup enabled" setting to stop backups; users revoke the
  /// grant in their Google account settings.
  Future<void> disconnect() => store.disconnect();

  /// Verifies and uploads [backup], replacing the previous backup of the same wallet.
  Future<CloudBackupFile> backup(WalletBackup backup) async {
    await backup.verify();
    final bytes = Uint8List.fromList(utf8.encode(backup.encode()));
    _validateSize(bytes.length);
    final file = await store.write(backupFileNameFor(backup.walletId), bytes);
    return file.withWalletId(backup.walletId);
  }

  /// Downloads, parses, and verifies the backup of [walletId].
  ///
  /// Throws [BackupNotFoundException] when no backup exists.
  Future<WalletBackup> restore(String walletId) async {
    final normalizedWalletId = normalizeWalletId(walletId);
    final bytes = await store.read(backupFileNameFor(normalizedWalletId));
    return _decode(bytes, normalizedWalletId);
  }

  /// Lists wallet backups, newest first, one entry per wallet.
  ///
  /// Every returned [CloudBackupFile.walletId] is non-null.
  Future<List<CloudBackupFile>> list() async {
    final walletIds = <String>{};
    final backups = <CloudBackupFile>[];
    for (final file in await store.list()) {
      final walletId = walletIdFromFileName(file.name);
      if (walletId != null && walletIds.add(walletId)) {
        backups.add(file.withWalletId(walletId));
      }
    }
    return List<CloudBackupFile>.unmodifiable(backups);
  }

  /// Permanently deletes the backup of [walletId].
  Future<void> delete(String walletId) async => store.delete(backupFileNameFor(walletId));

  /// Lists unresolved iCloud versions of [walletId]'s backup.
  ///
  /// Such versions appear when two devices back up the same wallet while
  /// offline. Always empty on Android, where Drive keeps a single version.
  Future<List<BackupConflictVersion>> listConflicts(String walletId) async {
    final store = this.store;
    if (store is! ConflictAwareBackupStore) {
      return const <BackupConflictVersion>[];
    }
    return store.listConflicts(backupFileNameFor(walletId));
  }

  /// Reads and verifies one unresolved version returned by [listConflicts].
  ///
  /// To keep that version, pass it to [backup] before [resolveConflicts].
  Future<WalletBackup> readConflictVersion(String walletId, String versionId) async {
    final store = this.store;
    if (store is! ConflictAwareBackupStore) {
      throw UnsupportedError('${store.provider.name} does not keep conflict versions.');
    }
    final normalizedWalletId = normalizeWalletId(walletId);
    final bytes = await store.readConflictVersion(backupFileNameFor(normalizedWalletId), versionId);
    return _decode(bytes, normalizedWalletId);
  }

  /// Marks [walletId]'s conflicts resolved after the app has reviewed them.
  ///
  /// Throws [BackupConflictException], and changes nothing, if a version not
  /// in [reviewedVersionIds] has appeared (checked immediately before
  /// resolving). With [removeOtherVersions] the losing versions are deleted.
  /// No-op on Android.
  Future<void> resolveConflicts(
    String walletId, {
    required Set<String> reviewedVersionIds,
    bool removeOtherVersions = false,
  }) async {
    final store = this.store;
    if (store is! ConflictAwareBackupStore) {
      return;
    }
    await store.resolveConflicts(
      backupFileNameFor(walletId),
      reviewedVersionIds: reviewedVersionIds,
      removeOtherVersions: removeOtherVersions,
    );
  }

  Future<WalletBackup> _decode(Uint8List bytes, String walletId) async {
    _validateSize(bytes.length);
    final String source;
    try {
      source = utf8.decode(bytes);
    } on FormatException catch (error) {
      throw BackupFormatException('Backup is not valid UTF-8.', cause: error);
    }
    final backup = await WalletBackup.decodeAndVerify(source);
    if (backup.walletId != walletId) {
      throw BackupIntegrityException(
        'The backup file for "$walletId" contains wallet "${backup.walletId}".',
      );
    }
    return backup;
  }

  void _validateSize(int size) {
    if (size > maxBackupSizeInBytes) {
      throw BackupFormatException(
        'Backup is $size bytes, exceeding the $maxBackupSizeInBytes byte limit.',
      );
    }
  }
}
