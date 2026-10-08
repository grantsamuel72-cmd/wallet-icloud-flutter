import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/data/wallet_database.dart';
import 'package:wallet_cloud_backup_example/data/wallet_repository.dart';
import 'package:wallet_cloud_backup_example/data/wallet_secret_store.dart';
import 'package:wallet_cloud_backup_example/domain/wallet_models.dart';
import 'package:wallet_cloud_backup_example/memory_backup_store.dart';
import 'package:wallet_core/wallet_core.dart';

import 'support/fake_wallet_core.dart';

const _cheap = BackupKdfParameters(
  memoryKiB: 64,
  iterations: 1,
  parallelism: 1,
);

class _MemorySecrets implements WalletSecretStore {
  final values = <String, String>{};

  @override
  Future<void> write(String reference, String secret) async =>
      values[reference] = secret;

  @override
  Future<String?> read(String reference) async => values[reference];

  @override
  Future<bool> contains(String reference) async =>
      values.containsKey(reference);

  @override
  Future<void> delete(String reference) async => values.remove(reference);
}

class _CountingBackupStore extends MemoryBackupStore {
  int writes = 0;

  @override
  Future<CloudBackupFile> write(String fileName, Uint8List contents) {
    writes++;
    return super.write(fileName, contents);
  }
}

class _CommittedThenTimedOutStore extends MemoryBackupStore {
  @override
  Future<CloudBackupFile> write(String fileName, Uint8List contents) async {
    await super.write(fileName, contents);
    throw const CloudStorageException('upload timed out after commit');
  }
}

void main() {
  late WalletDatabase database;
  late _MemorySecrets secrets;
  late WalletRepository repository;
  late MnemonicCloudBackup backups;
  late _CountingBackupStore cloudStore;

  setUp(() {
    database = WalletDatabase(NativeDatabase.memory());
    secrets = _MemorySecrets();
    final core = WalletCore(platform: FakeWalletCore());
    cloudStore = _CountingBackupStore();
    backups = MnemonicCloudBackup.forTesting(
      WalletCloudBackup.withStore(cloudStore),
      walletCore: core,
      kdf: _cheap,
      minimumKdf: _cheap,
    );
    repository = WalletRepository(
      database: database,
      secrets: secrets,
      core: core,
      backups: backups,
      random: Random(3),
    );
  });

  tearDown(() async => database.close());

  test(
    'HD creation stores only a secret reference and exact address paths in Drift',
    () async {
      final created = await repository.createHd(name: '主钱包');
      expect(created.mnemonic, firstGeneratedMnemonic);

      final wallet = (await repository.listWallets()).single;
      expect(wallet.kind, WalletKind.hd);
      expect(wallet.addresses.length, 3);
      expect(wallet.addresses.map((a) => a.path), contains("m/44'/60'/0'/0/0"));
      final row = (await database.select(database.walletRows).get()).single;
      expect(row.secretRef, 'wallet/${created.id}/mnemonic');
      expect(row.toString(), isNot(contains(firstGeneratedMnemonic)));
      expect(secrets.values[row.secretRef], firstGeneratedMnemonic);

      await repository.addHdAddress(created.id, WalletChain.tron, 1);
      final addresses = (await repository.listWallets()).single.addresses;
      expect(addresses.map((a) => a.path), contains("m/44'/195'/0'/0/1"));
      await repository.verifyLocalWallet(created.id);
    },
  );

  test(
    'imported key and watch-only wallets have separate secret policies',
    () async {
      final imported = await repository.importPrivateKey(
        name: '独立密钥',
        keyHex: '11' * 32,
      );
      final watched = await repository.addWatchOnly(
        name: '只读',
        chain: WalletChain.evm,
        address: '0xWATCH',
      );
      final wallets = await repository.listWallets();
      expect(wallets.length, 2);
      expect(
        wallets.firstWhere((w) => w.id == imported.id).addresses.length,
        3,
      );
      expect(
        wallets.firstWhere((w) => w.id == watched.id).kind,
        WalletKind.watchOnly,
      );
      expect(secrets.values.length, 1);
      await repository.verifyLocalWallet(imported.id);
      await repository.verifyLocalWallet(watched.id);

      await repository.deleteLocal(imported.id);
      expect(secrets.values, isEmpty);
      expect((await repository.listWallets()).single.id, watched.id);
    },
  );

  test(
    'cloud backup restores a deleted HD wallet with its default addresses',
    () async {
      final created = await repository.createHd(name: '待恢复');
      await repository.backupHd(created.id, 'correct horse battery');
      expect((await repository.listWallets()).single.backupState, 'verified');
      final entry = (await repository.listCloudWallets()).single;
      await repository.deleteLocal(created.id);

      await repository.restoreHd(entry, 'correct horse battery');
      final wallet = (await repository.listWallets()).single;
      expect(wallet.id, created.id);
      expect(wallet.addresses.length, 3);
      await repository.verifyLocalWallet(wallet.id);
    },
  );

  test(
    'skips an existing matching cloud backup without writing again',
    () async {
      final created = await repository.createHd(name: '主钱包');
      expect(
        await repository.backupHd(created.id, 'correct horse battery'),
        BackupHdResult.uploaded,
      );
      final checksum = (await backups.cloud.restore(created.id)).checksum;
      final backedUpAt = (await repository.listWallets()).single.lastBackedUpAt;

      expect(
        await repository.backupHd(created.id, 'correct horse battery'),
        BackupHdResult.alreadyBackedUp,
      );
      expect(cloudStore.writes, 1);
      expect((await backups.cloud.restore(created.id)).checksum, checksum);
      expect((await repository.listWallets()).single.backupState, 'verified');
      expect(
        (await repository.listWallets()).single.lastBackedUpAt,
        backedUpAt,
      );

      await backups.cloud.delete(created.id);
      expect(
        await repository.backupHd(created.id, 'correct horse battery'),
        BackupHdResult.uploaded,
      );
      expect(cloudStore.writes, 2);
    },
  );

  test('wrong password never replaces an existing cloud backup', () async {
    final created = await repository.createHd(name: '主钱包');
    await repository.backupHd(created.id, 'correct horse battery');

    await expectLater(
      repository.backupHd(created.id, 'another long password'),
      throwsA(isA<WrongBackupPasswordException>()),
    );
    expect(cloudStore.writes, 1);
    expect((await repository.listWallets()).single.backupState, 'verified');
  });

  test(
    'a timed-out upload is marked verified only after reading it back',
    () async {
      final core = WalletCore(platform: FakeWalletCore());
      final timeoutBackups = MnemonicCloudBackup.forTesting(
        WalletCloudBackup.withStore(_CommittedThenTimedOutStore()),
        walletCore: core,
        kdf: _cheap,
        minimumKdf: _cheap,
      );
      repository.useCloud(timeoutBackups, 'huawei:one');
      final created = await repository.createHd(name: '主钱包');
      expect(
        await repository.backupHd(created.id, 'correct horse battery'),
        BackupHdResult.uploaded,
      );
      expect((await repository.listWallets()).single.backupState, 'verified');
      repository.useCloud(backups, 'huawei:two');
      expect((await repository.listWallets()).single.backupState, 'none');
    },
  );

  test(
    'additional wallet requires an existing password unless recovery is chosen',
    () async {
      final first = await repository.createHd(name: '一');
      final second = await repository.createHd(name: '二');
      await repository.backupHd(first.id, 'correct horse battery');
      await expectLater(
        repository.backupHd(second.id, 'different password'),
        throwsA(isA<WrongBackupPasswordException>()),
      );
      expect(cloudStore.writes, 1);
      await repository.backupHd(
        second.id,
        'different password',
        useNewPassword: true,
      );
      expect(cloudStore.writes, 2);
      expect(
        await backups.verifyPassword(
          first.id,
          password: 'correct horse battery',
        ),
        isTrue,
      );
    },
  );

  test(
    'different cloud mnemonic with the same ID is never overwritten',
    () async {
      final created = await repository.createHd(name: '主钱包');
      await backups.backupMnemonic(
        walletId: created.id,
        mnemonic: secondGeneratedMnemonic,
        password: 'correct horse battery',
      );

      await expectLater(
        repository.backupHd(created.id, 'correct horse battery'),
        throwsA(isA<StateError>()),
      );
      expect(cloudStore.writes, 1);
      expect(
        await backups.restoreMnemonic(
          created.id,
          password: 'correct horse battery',
        ),
        secondGeneratedMnemonic,
      );
    },
  );

  test(
    'restore refuses mismatched secret and repairs an existing wallet missing its secret',
    () async {
      final created = await repository.createHd(name: '待修复');
      await repository.backupHd(created.id, 'correct horse battery');
      await repository.addHdAddress(created.id, WalletChain.tron, 1);
      final entry = (await repository.listCloudWallets()).single;
      final secretRef =
          (await database.select(database.walletRows).getSingle()).secretRef!;
      await secrets.delete(secretRef);
      expect((await repository.listWallets()).single.state, 'needs_restore');

      await repository.restoreHd(entry, 'correct horse battery');
      expect((await repository.listWallets()).single.state, 'ready');
      expect((await repository.listWallets()).single.addresses.length, 4);
      await repository.verifyLocalWallet(created.id);
    },
  );

  test(
    'wallet metadata survives closing and reopening the SQLite file',
    () async {
      // A separate in-memory fixture database stays open in this test group.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );
      final directory = await Directory.systemTemp.createTemp(
        'wallet-example-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File(p.join(directory.path, 'wallet.sqlite'));
      final first = WalletDatabase(NativeDatabase(file));
      final core = WalletCore(platform: FakeWalletCore());
      final store = _MemorySecrets();
      final backups = MnemonicCloudBackup.forTesting(
        WalletCloudBackup.withStore(MemoryBackupStore()),
        walletCore: core,
        kdf: _cheap,
        minimumKdf: _cheap,
      );
      final firstRepository = WalletRepository(
        database: first,
        secrets: store,
        core: core,
        backups: backups,
        random: Random(7),
      );
      final created = await firstRepository.createHd(name: '持久钱包');
      await first.close();

      final reopened = WalletDatabase(NativeDatabase(file));
      try {
        final secondRepository = WalletRepository(
          database: reopened,
          secrets: store,
          core: core,
          backups: backups,
        );
        final wallets = await secondRepository.listWallets();
        expect(wallets.single.id, created.id);
        expect(wallets.single.addresses.length, 3);
        await secondRepository.verifyLocalWallet(created.id);
      } finally {
        await reopened.close();
      }
    },
  );
}
