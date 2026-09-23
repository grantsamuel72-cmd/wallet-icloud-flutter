import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Namespaced device-local storage for login hints, tokens, or cache secrets.
///
/// Values here are not a cross-device recovery mechanism. Never make a cloud
/// backup recoverable only through a key stored by this class.
class LocalBackupCache {
  /// Creates a local cache.
  LocalBackupCache({FlutterSecureStorage? storage, this.namespace = 'wallet_cloud_backup'})
    : _storage = storage ?? const FlutterSecureStorage() {
    if (namespace.trim().isEmpty) {
      throw ArgumentError.value(namespace, 'namespace', 'Must not be empty.');
    }
  }

  final FlutterSecureStorage _storage;

  /// Prefix isolating this package's values from other secure-storage users.
  final String namespace;

  /// Writes a device-local value.
  Future<void> write(String key, String value) {
    return _storage.write(key: _key(key), value: value);
  }

  /// Reads a device-local value.
  Future<String?> read(String key) {
    return _storage.read(key: _key(key));
  }

  /// Deletes a device-local value.
  Future<void> delete(String key) {
    return _storage.delete(key: _key(key));
  }

  String _key(String key) {
    final normalized = key.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Must not be empty.');
    }
    return '$namespace.$normalized';
  }
}
