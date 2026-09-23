import 'dart:convert';

import 'package:wallet_cloud_backup/src/domain/exceptions.dart';

/// Maximum UTF-8 length of a wallet identifier.
///
/// Keeps generated file names well below the 255-byte limit of iCloud Drive.
const int maxWalletIdLengthInBytes = 100;

final RegExp _backupFileName = RegExp(r'^wallet-((?:[0-9a-f]{2})+)\.json$');

/// Trims and validates a wallet identifier.
String normalizeWalletId(String walletId) {
  final normalized = walletId.trim();
  if (normalized.isEmpty) {
    throw const BackupFormatException('walletId must not be empty.');
  }
  final encoded = utf8.encode(normalized);
  // utf8.encode maps unpaired surrogates to U+FFFD, which would let two
  // different ids share one file.
  if (utf8.decode(encoded) != normalized) {
    throw const BackupFormatException('walletId must be valid Unicode text.');
  }
  if (encoded.length > maxWalletIdLengthInBytes) {
    throw const BackupFormatException(
      'walletId must be at most $maxWalletIdLengthInBytes UTF-8 bytes.',
    );
  }
  if (normalized.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    throw const BackupFormatException('walletId must not contain control characters.');
  }
  return normalized;
}

/// Returns the deterministic backup file name for [walletId].
///
/// The identifier is hex-encoded so the name is reversible, portable, and
/// cannot collide on case-insensitive file systems such as iCloud Drive's.
String backupFileNameFor(String walletId) {
  final bytes = utf8.encode(normalizeWalletId(walletId));
  return 'wallet-${bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}.json';
}

/// Returns the wallet identifier encoded in [fileName], or null for other files.
String? walletIdFromFileName(String fileName) {
  final hex = _backupFileName.firstMatch(fileName)?.group(1);
  if (hex == null) {
    return null;
  }
  final bytes = <int>[
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ];
  try {
    final walletId = utf8.decode(bytes);
    return backupFileNameFor(walletId) == fileName ? walletId : null;
  } on FormatException {
    return null;
  } on BackupFormatException {
    return null;
  }
}

/// Maximum UTF-8 length of a cloud file name.
///
/// iCloud Drive and Google Drive both stop at 255 bytes per path component.
const int maxBackupFileNameLengthInBytes = 255;

/// Throws unless [fileName] is a plain file name a store may use as-is.
///
/// Part of the [CloudBackupStore] contract: a custom store should call this
/// before building a provider path, so every backend rejects the same names.
///
/// Stores build provider paths by concatenation, so a name that is empty or
/// carries path syntax would address something other than one file. On iCloud
/// an empty name yields the container folder itself, which the plugin deletes
/// recursively; rejecting it here keeps both backends on the same contract.
String assertPlainBackupFileName(String fileName) {
  final invalid =
      fileName.trim().isEmpty ||
      fileName.startsWith('.') ||
      fileName.contains('/') ||
      fileName.contains(':') ||
      utf8.encode(fileName).length > maxBackupFileNameLengthInBytes;
  if (invalid) {
    throw ArgumentError.value(fileName, 'fileName', 'Must be a plain backup file name.');
  }
  return fileName;
}
