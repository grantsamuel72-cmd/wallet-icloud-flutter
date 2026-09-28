import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class WalletSecretStore {
  Future<void> write(String reference, String secret);
  Future<String?> read(String reference);
  Future<bool> contains(String reference);
  Future<void> delete(String reference);
}

class SecureWalletSecretStore implements WalletSecretStore {
  SecureWalletSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String reference, String secret) => _storage.write(
    key: reference,
    value: secret,
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  @override
  Future<String?> read(String reference) => _storage.read(key: reference);

  @override
  Future<bool> contains(String reference) =>
      _storage.containsKey(key: reference);

  @override
  Future<void> delete(String reference) => _storage.delete(key: reference);
}
