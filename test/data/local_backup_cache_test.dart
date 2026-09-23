import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalBackupCache', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

    test('writes, reads and deletes values', () async {
      final cache = LocalBackupCache();

      await cache.write('hint', 'value');
      expect(await cache.read('hint'), 'value');

      await cache.delete('hint');
      expect(await cache.read('hint'), isNull);
    });

    test('stores keys under its namespace', () async {
      const storage = FlutterSecureStorage();
      final cache = LocalBackupCache(storage: storage, namespace: 'wallet');

      await cache.write('hint', 'value');

      expect(await storage.read(key: 'wallet.hint'), 'value');
      expect(await storage.read(key: 'hint'), isNull);
    });

    test('isolates namespaces from each other', () async {
      final first = LocalBackupCache(namespace: 'a');
      final second = LocalBackupCache(namespace: 'b');

      await first.write('key', 'from a');

      expect(await second.read('key'), isNull);
      expect(await first.read('key'), 'from a');
    });

    test('trims keys', () async {
      final cache = LocalBackupCache();

      await cache.write('  hint  ', 'value');

      expect(await cache.read('hint'), 'value');
    });

    test('rejects empty keys and namespaces', () {
      final cache = LocalBackupCache();

      expect(() => cache.write(' ', 'value'), throwsArgumentError);
      expect(() => cache.read(''), throwsArgumentError);
      expect(() => LocalBackupCache(namespace: '  '), throwsArgumentError);
    });
  });
}
