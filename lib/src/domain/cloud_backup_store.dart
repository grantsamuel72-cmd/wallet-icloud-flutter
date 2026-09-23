import 'dart:typed_data';

import 'package:wallet_cloud_backup/src/domain/cloud_backup_file.dart';

/// Default maximum size of one serialized backup: 10 MiB.
const int defaultMaxBackupSizeInBytes = 10 * 1024 * 1024;

/// Provider-independent storage contract used by [WalletCloudBackup].
///
/// Runtime failures are [WalletCloudBackupException]s. Caller mistakes keep
/// their usual types: a name that is not a plain backup file name is an
/// [ArgumentError], reported through the returned future.
abstract interface class CloudBackupStore {
  /// Provider implemented by this store.
  CloudBackupProvider get provider;

  /// Makes the provider ready for use.
  ///
  /// With [interactive] false no UI is shown, and false is returned when the
  /// provider is unavailable or needs user interaction. With [interactive]
  /// true the provider may show sign-in or consent UI; call it from a user
  /// action. Returns false when the user cancels.
  Future<bool> connect({bool interactive = false});

  /// Forgets the local authorization, if any.
  Future<void> disconnect();

  /// Creates or replaces a backup named [fileName].
  Future<CloudBackupFile> write(String fileName, Uint8List contents);

  /// Reads a complete backup named [fileName].
  Future<Uint8List> read(String fileName);

  /// Lists all files visible to this application, newest first.
  Future<List<CloudBackupFile>> list();

  /// Permanently deletes every file named [fileName].
  Future<void> delete(String fileName);
}

/// A store whose provider can keep several unresolved versions of one file (iCloud).
abstract interface class ConflictAwareBackupStore implements CloudBackupStore {
  /// Returns unresolved versions without selecting a winner or deleting data.
  Future<List<BackupConflictVersion>> listConflicts(String fileName);

  /// Reads the bytes of one unresolved version.
  Future<Uint8List> readConflictVersion(String fileName, String versionId);

  /// Marks conflicts resolved, but only if every unresolved version is in
  /// [reviewedVersionIds]. Otherwise throws [BackupConflictException] and
  /// changes nothing. The check runs immediately before resolving; a version
  /// arriving between the check and the resolve cannot be excluded.
  Future<void> resolveConflicts(
    String fileName, {
    required Set<String> reviewedVersionIds,
    required bool removeOtherVersions,
  });
}
