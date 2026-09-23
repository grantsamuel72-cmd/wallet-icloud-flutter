/// Supported cloud providers.
enum CloudBackupProvider {
  /// Apple iCloud Drive ubiquity container (iOS).
  iCloud,

  /// Google Drive's hidden application data folder (Android).
  googleDrive,
}

/// Metadata describing a cloud backup object.
class CloudBackupFile {
  /// Creates immutable cloud backup metadata.
  const CloudBackupFile({
    required this.id,
    required this.name,
    required this.provider,
    this.walletId,
    this.createdAt,
    this.modifiedAt,
    this.sizeInBytes,
    this.hasUnresolvedConflicts = false,
  });

  /// Provider-specific stable identifier.
  final String id;

  /// Backup file name.
  final String name;

  /// Cloud provider that owns the file.
  final CloudBackupProvider provider;

  /// Wallet identifier encoded in [name], or null for files not created by this package.
  final String? walletId;

  /// Creation time reported by the provider.
  final DateTime? createdAt;

  /// Last modification time reported by the provider.
  final DateTime? modifiedAt;

  /// File size reported by the provider.
  final int? sizeInBytes;

  /// Whether iCloud reports unresolved document versions. Always false on Google Drive.
  final bool hasUnresolvedConflicts;

  /// Returns a copy with [walletId] set.
  CloudBackupFile withWalletId(String? walletId) => CloudBackupFile(
    id: id,
    name: name,
    provider: provider,
    walletId: walletId,
    createdAt: createdAt,
    modifiedAt: modifiedAt,
    sizeInBytes: sizeInBytes,
    hasUnresolvedConflicts: hasUnresolvedConflicts,
  );
}

/// A losing iCloud document version that has not been resolved yet.
class BackupConflictVersion {
  /// Creates a conflict descriptor.
  const BackupConflictVersion({required this.id, this.modifiedAt});

  /// Opaque identifier understood by iCloud.
  final String id;

  /// Version modification time, when available.
  final DateTime? modifiedAt;
}

/// Orders backups newest first, by modification time and then creation time.
///
/// Part of the [CloudBackupStore] contract: a custom store should sort its
/// `list()` result with this so it answers like the built-in backends.
///
/// Both backends sort with this, so `list()` returns the same order whatever
/// the provider reports. Entries with no time at all sort last, then by name,
/// which keeps the result stable.
int compareBackupsNewestFirst(CloudBackupFile left, CloudBackupFile right) {
  final leftTime = left.modifiedAt ?? left.createdAt;
  final rightTime = right.modifiedAt ?? right.createdAt;
  if (leftTime == null && rightTime == null) return left.name.compareTo(right.name);
  if (leftTime == null) return 1;
  if (rightTime == null) return -1;
  return rightTime.compareTo(leftTime);
}
