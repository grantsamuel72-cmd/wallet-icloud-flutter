import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:wallet_cloud_backup/src/domain/backup_file_names.dart';
import 'package:wallet_cloud_backup/src/domain/canonical_json.dart';
import 'package:wallet_cloud_backup/src/domain/exceptions.dart';

/// Versioned backup envelope containing an already encrypted Wallet Core keystore.
class WalletBackup {
  WalletBackup._({
    required this.formatVersion,
    required this.walletId,
    required this.encryptedKeystore,
    required this.createdAt,
    required this.checksum,
  });

  /// Current JSON envelope version.
  static const int currentFormatVersion = 1;

  /// JSON envelope version.
  final int formatVersion;

  /// Application-defined wallet identifier, for example a UUID.
  ///
  /// It names the cloud file, so it must not contain secret material. At most
  /// [maxWalletIdLengthInBytes] UTF-8 bytes; surrounding whitespace is trimmed.
  final String walletId;

  /// Wallet Core keystore JSON or another password-encrypted keystore object.
  final Map<String, Object?> encryptedKeystore;

  /// Time at which this backup envelope was created.
  final DateTime createdAt;

  /// SHA-256 checksum of the canonical envelope fields excluding this checksum.
  final String checksum;

  /// Creates a new checksummed backup around an already encrypted keystore.
  static Future<WalletBackup> create({
    required String walletId,
    required Map<String, Object?> encryptedKeystore,
    DateTime? createdAt,
  }) async {
    final normalizedWalletId = normalizeWalletId(walletId);
    if (encryptedKeystore.isEmpty) {
      throw const BackupFormatException('encryptedKeystore must not be empty.');
    }

    final normalizedKeystore = _normalizeMap(encryptedKeystore);
    final normalizedCreatedAt = (createdAt ?? DateTime.now()).toUtc();
    final fields = _contentFields(
      formatVersion: currentFormatVersion,
      walletId: normalizedWalletId,
      encryptedKeystore: normalizedKeystore,
      createdAt: normalizedCreatedAt,
    );

    return WalletBackup._(
      formatVersion: currentFormatVersion,
      walletId: normalizedWalletId,
      encryptedKeystore: normalizedKeystore,
      createdAt: normalizedCreatedAt,
      checksum: await _checksum(fields),
    );
  }

  /// Parses and verifies a backup JSON document.
  static Future<WalletBackup> decodeAndVerify(String source) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(source) as Object?;
    } on FormatException catch (error) {
      throw BackupFormatException('Backup is not valid JSON.', cause: error);
    }
    if (decoded is! Map<String, Object?>) {
      throw const BackupFormatException('Backup root must be a JSON object.');
    }

    final formatVersion = decoded['formatVersion'];
    final walletId = decoded['walletId'];
    final encryptedKeystore = decoded['encryptedKeystore'];
    final createdAtValue = decoded['createdAt'];
    final checksum = decoded['checksum'];

    if (formatVersion is! int || formatVersion != currentFormatVersion) {
      throw BackupFormatException('Unsupported formatVersion: $formatVersion.');
    }
    if (walletId is! String || normalizeWalletId(walletId) != walletId) {
      throw const BackupFormatException('walletId must be a trimmed, non-empty string.');
    }
    if (encryptedKeystore is! Map<String, Object?> || encryptedKeystore.isEmpty) {
      throw const BackupFormatException('encryptedKeystore must be a non-empty object.');
    }
    if (createdAtValue is! String) {
      throw const BackupFormatException('createdAt must be an ISO-8601 string.');
    }
    if (checksum is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) {
      throw const BackupFormatException('checksum must be a lowercase SHA-256 hex string.');
    }

    final DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtValue).toUtc();
    } on FormatException catch (error) {
      throw BackupFormatException('createdAt is not a valid ISO-8601 value.', cause: error);
    }

    final normalizedKeystore = _normalizeMap(encryptedKeystore);
    final fields = _contentFields(
      formatVersion: formatVersion,
      walletId: walletId,
      encryptedKeystore: normalizedKeystore,
      createdAt: createdAt,
    );
    final actualChecksum = await _checksum(fields);
    if (actualChecksum != checksum) {
      throw const BackupIntegrityException('Backup checksum verification failed.');
    }

    return WalletBackup._(
      formatVersion: formatVersion,
      walletId: walletId,
      encryptedKeystore: normalizedKeystore,
      createdAt: createdAt,
      checksum: checksum,
    );
  }

  /// Returns the portable JSON representation of the backup.
  Map<String, Object?> toJson() => <String, Object?>{
    ..._contentFields(
      formatVersion: formatVersion,
      walletId: walletId,
      encryptedKeystore: encryptedKeystore,
      createdAt: createdAt,
    ),
    'checksum': checksum,
  };

  /// Encodes the backup as compact JSON.
  String encode() => jsonEncode(toJson());

  /// Recomputes and validates [checksum].
  Future<void> verify() async {
    final actual = await _checksum(
      _contentFields(
        formatVersion: formatVersion,
        walletId: walletId,
        encryptedKeystore: encryptedKeystore,
        createdAt: createdAt,
      ),
    );
    if (actual != checksum) {
      throw const BackupIntegrityException('Backup checksum verification failed.');
    }
  }

  static Map<String, Object?> _contentFields({
    required int formatVersion,
    required String walletId,
    required Map<String, Object?> encryptedKeystore,
    required DateTime createdAt,
  }) => <String, Object?>{
    'formatVersion': formatVersion,
    'walletId': walletId,
    'encryptedKeystore': encryptedKeystore,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  static Future<String> _checksum(Map<String, Object?> fields) async {
    final canonical = canonicalJsonEncode(fields);
    final hash = await Sha256().hash(utf8.encode(canonical));
    return hash.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  // Deep enough for any real keystore, shallow enough that a crafted file
  // cannot overflow the stack.
  static const int _maxDepth = 64;

  static Map<String, Object?> _normalizeMap(Map<String, Object?> value, [int depth = 0]) {
    if (depth > _maxDepth) {
      throw const BackupFormatException('encryptedKeystore is nested too deeply.');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      result[entry.key] = _normalizeValue(entry.value, depth + 1);
    }
    return Map<String, Object?>.unmodifiable(result);
  }

  static Object? _normalizeValue(Object? value, int depth) {
    if (value == null || value is bool || value is String || value is int) {
      return value;
    }
    if (value is double) {
      if (!value.isFinite) {
        throw const BackupFormatException('JSON numbers must be finite.');
      }
      return value;
    }
    if (value is List<Object?>) {
      if (depth > _maxDepth) {
        throw const BackupFormatException('encryptedKeystore is nested too deeply.');
      }
      return List<Object?>.unmodifiable(value.map((item) => _normalizeValue(item, depth + 1)));
    }
    if (value is Map<String, Object?>) {
      return _normalizeMap(value, depth);
    }
    throw BackupFormatException(
      'encryptedKeystore contains a non-JSON value: ${value.runtimeType}.',
    );
  }
}
