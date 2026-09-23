import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  group('WalletCloudBackup platform selection', () {
    const iCloud = ICloudOptions(containerId: 'iCloud.com.example.wallet');

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('uses iCloud on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final cloud = WalletCloudBackup(iCloud: iCloud);

      expect(cloud.provider, CloudBackupProvider.iCloud);
      expect(cloud.store, isA<ConflictAwareBackupStore>());
    });

    test('uses Google Drive on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(WalletCloudBackup(iCloud: iCloud).provider, CloudBackupProvider.googleDrive);
    });

    test('rejects other platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      expect(() => WalletCloudBackup(iCloud: iCloud), throwsUnsupportedError);
    });
  });

  group('WalletCloudBackup', () {
    late _MemoryStore store;
    late WalletCloudBackup cloud;

    setUp(() {
      store = _MemoryStore();
      cloud = WalletCloudBackup.withStore(store);
    });

    Future<WalletBackup> backupOf(String walletId) => WalletBackup.create(
      walletId: walletId,
      encryptedKeystore: <String, Object?>{'ciphertext': 'encrypted-$walletId'},
    );

    test('backs up and restores a verified wallet envelope', () async {
      final backup = await backupOf('wallet-1');

      final metadata = await cloud.backup(backup);
      final restored = await cloud.restore('wallet-1');

      expect(metadata.walletId, 'wallet-1');
      expect(restored.walletId, backup.walletId);
      expect(restored.checksum, backup.checksum);
    });

    test('keeps one file per wallet', () async {
      await cloud.backup(await backupOf('wallet-1'));
      await cloud.backup(await backupOf('wallet-2'));

      expect(store.files, hasLength(2));
      expect(
        (await cloud.restore('wallet-1')).encryptedKeystore['ciphertext'],
        'encrypted-wallet-1',
      );
      expect(
        (await cloud.restore('wallet-2')).encryptedKeystore['ciphertext'],
        'encrypted-wallet-2',
      );
    });

    test('lists only wallet backups, with their wallet ids', () async {
      await cloud.backup(await backupOf('wallet-1'));
      store.files['notes.txt'] = Uint8List(1);

      final backups = await cloud.list();

      expect(backups.map((file) => file.walletId), <String>['wallet-1']);
    });

    test('deletes one wallet backup', () async {
      await cloud.backup(await backupOf('wallet-1'));
      await cloud.backup(await backupOf('wallet-2'));

      await cloud.delete('wallet-1');

      expect((await cloud.list()).map((file) => file.walletId), <String>['wallet-2']);
      await expectLater(cloud.restore('wallet-1'), throwsA(isA<BackupNotFoundException>()));
    });

    test('rejects a file whose content belongs to another wallet', () async {
      await cloud.backup(await backupOf('wallet-1'));
      final swapped = store.files.values.single;
      store.files
        ..clear()
        ..[(await cloud.backup(await backupOf('wallet-2'))).name] = swapped;

      await expectLater(cloud.restore('wallet-2'), throwsA(isA<BackupIntegrityException>()));
    });

    test('rejects invalid UTF-8', () async {
      await cloud.backup(await backupOf('wallet-1'));
      store.files.updateAll((_, _) => Uint8List.fromList(<int>[0xff]));

      await expectLater(cloud.restore('wallet-1'), throwsA(isA<BackupFormatException>()));
    });

    test('enforces the size limit', () async {
      cloud = WalletCloudBackup.withStore(store, maxBackupSizeInBytes: 10);

      await expectLater(
        cloud.backup(await backupOf('wallet-1')),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('answers conflict queries per method on stores without versions', () async {
      expect(await cloud.listConflicts('wallet-1'), isEmpty);
      await cloud.resolveConflicts('wallet-1', reviewedVersionIds: <String>{});
      await expectLater(cloud.readConflictVersion('wallet-1', 'v1'), throwsUnsupportedError);
    });

    test('propagates a typed not-found error', () async {
      await expectLater(cloud.restore('missing'), throwsA(isA<BackupNotFoundException>()));
    });

    test('stores the backup as JSON', () async {
      await cloud.backup(await backupOf('wallet-1'));

      final json = jsonDecode(utf8.decode(store.files.values.single)) as Map<String, Object?>;
      expect(json['walletId'], 'wallet-1');
    });
  });
}

class _MemoryStore implements CloudBackupStore {
  final Map<String, Uint8List> files = <String, Uint8List>{};

  @override
  CloudBackupProvider get provider => CloudBackupProvider.googleDrive;

  @override
  Future<bool> connect({bool interactive = false}) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> delete(String fileName) async {
    if (files.remove(fileName) == null) {
      throw BackupNotFoundException(fileName);
    }
  }

  @override
  Future<List<CloudBackupFile>> list() async => files.entries
      .map(
        (entry) => CloudBackupFile(
          id: entry.key,
          name: entry.key,
          provider: provider,
          sizeInBytes: entry.value.length,
        ),
      )
      .toList(growable: false);

  @override
  Future<Uint8List> read(String fileName) async {
    final value = files[fileName];
    if (value == null) {
      throw BackupNotFoundException(fileName);
    }
    return Uint8List.fromList(value);
  }

  @override
  Future<CloudBackupFile> write(String fileName, Uint8List contents) async {
    files[fileName] = Uint8List.fromList(contents);
    return CloudBackupFile(
      id: fileName,
      name: fileName,
      provider: provider,
      sizeInBytes: contents.length,
    );
  }
}
