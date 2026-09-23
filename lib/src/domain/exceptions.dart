/// Base exception for package-level backup failures.
///
/// Every runtime failure of this package's public API is this type or a
/// subclass, so callers can catch this single type. Caller mistakes keep their
/// usual types, for example [ArgumentError] for an invalid argument.
/// [LocalBackupCache] is outside this guarantee: it passes secure-storage
/// errors through unchanged. Provider-specific errors are kept in [cause].
class WalletCloudBackupException implements Exception {
  /// Creates a backup exception with an optional underlying [cause].
  const WalletCloudBackupException(this.message, {this.cause});

  /// Human-readable error description.
  final String message;

  /// Original error, when one is available.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a backup document is malformed or unsupported.
class BackupFormatException extends WalletCloudBackupException {
  /// Creates a backup format exception.
  const BackupFormatException(super.message, {super.cause});
}

/// Thrown when a backup checksum or authentication tag is invalid.
class BackupIntegrityException extends WalletCloudBackupException {
  /// Creates a backup integrity exception.
  const BackupIntegrityException(super.message, {super.cause});
}

/// Thrown when the requested cloud backup does not exist.
class BackupNotFoundException extends WalletCloudBackupException {
  /// Creates a not-found exception for [fileName].
  BackupNotFoundException(this.fileName, {super.cause})
    : super('Backup "$fileName" was not found.');

  /// Requested backup file name.
  final String fileName;
}

/// Thrown when new iCloud conflict versions appeared after the caller reviewed them.
class BackupConflictException extends WalletCloudBackupException {
  /// Creates a conflict exception listing the [unreviewedVersionIds].
  BackupConflictException(this.unreviewedVersionIds)
    : super(
        'New conflict versions appeared since they were reviewed: '
        '${unreviewedVersionIds.join(', ')}.',
      );

  /// Versions that must be reviewed before conflicts can be resolved.
  final Set<String> unreviewedVersionIds;
}

/// Thrown when cloud authentication or authorization is missing or rejected.
class CloudAuthenticationException extends WalletCloudBackupException {
  /// Creates a cloud authentication exception.
  const CloudAuthenticationException(super.message, {super.cause});
}

/// Thrown when the provider cannot be used on this device, for example when
/// the user is not signed in to iCloud or iCloud Drive is disabled.
class CloudUnavailableException extends WalletCloudBackupException {
  /// Creates a provider-unavailable exception.
  const CloudUnavailableException(super.message, {super.cause});
}

/// Thrown for other provider, network, or file-coordination failures.
class CloudStorageException extends WalletCloudBackupException {
  /// Creates a storage exception.
  const CloudStorageException(super.message, {super.cause});
}

/// Thrown when the password does not open a mnemonic backup.
///
/// Detected with a key-check value derived from the password before any
/// decryption, so it does not mean the file is damaged. Someone able to
/// rewrite the cloud file can also cause it by changing the key parameters.
class WrongBackupPasswordException extends WalletCloudBackupException {
  /// Creates a wrong-password exception.
  const WrongBackupPasswordException() : super('The backup password is incorrect.');
}

/// Thrown when a new backup password is shorter than the required minimum.
class WeakBackupPasswordException extends WalletCloudBackupException {
  /// Creates a weak-password exception for a policy of [minLength] characters.
  const WeakBackupPasswordException(this.minLength)
    : super('The backup password must have at least $minLength characters.');

  /// Minimum number of characters (Unicode code points).
  final int minLength;
}

/// Thrown when a mnemonic is not a valid BIP39 phrase. The message never contains the phrase.
class InvalidMnemonicException extends WalletCloudBackupException {
  /// Creates an invalid-mnemonic exception.
  const InvalidMnemonicException({super.cause})
    : super('The mnemonic is not a valid BIP39 phrase.');
}

/// Thrown when Wallet Core cannot run in this build, for example an Android ABI
/// without its native library, or a unit test without a fake platform.
class WalletCoreUnavailableException extends WalletCloudBackupException {
  /// Creates a Wallet Core availability exception.
  const WalletCoreUnavailableException(super.message, {super.cause});
}
