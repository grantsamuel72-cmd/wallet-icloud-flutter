import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_core/wallet_core.dart';

import '../support/fake_wallet_core.dart';
import '../support/memory_backup_store.dart';

const _cheap = BackupKdfParameters(memoryKiB: 64, iterations: 1, parallelism: 1);
const _password = 'correct horse battery';

void main() {
  late MemoryBackupStore store;
  late FakeWalletCorePlatform platform;
  late MnemonicCloudBackup backups;

  MnemonicCloudBackup create({WalletCore? walletCore}) => MnemonicCloudBackup.forTesting(
    WalletCloudBackup.withStore(store),
    walletCore: walletCore ?? WalletCore(platform: platform),
    kdf: _cheap,
    minimumKdf: _cheap,
    random: Random(7),
  );

  setUp(() {
    store = MemoryBackupStore();
    platform = FakeWalletCorePlatform();
    backups = create();
  });

  test('backs up and restores a mnemonic', () async {
    final file = await backups.backupMnemonic(
      walletId: 'wallet-1',
      mnemonic: '  ${mnemonic12.replaceAll(' ', '   ')}\n',
      password: _password,
      label: 'Main',
    );

    expect(file.walletId, 'wallet-1');
    expect(await backups.restoreMnemonic('wallet-1', password: _password), mnemonic12);
    expect(platform.wallets, isEmpty, reason: 'temporary wallets are disposed');
  });

  test('uploads nothing that reveals the wallet', () async {
    await backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password);

    final json = utf8.decode(store.files.values.single);
    expect(json, isNot(contains('abandon')));
    expect(json, isNot(contains(_password)));
  });

  test('rejects a short password before doing any work', () async {
    await expectLater(
      backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: 'short'),
      throwsA(isA<WeakBackupPasswordException>().having((e) => e.minLength, 'minLength', 8)),
    );
    expect(store.writes, 0);
    expect(platform.importedPassphrases, isEmpty, reason: 'Wallet Core was not called');
  });

  test('rejects an invalid mnemonic without writing', () async {
    const phrase = 'these words are not a valid recovery phrase at all okay';

    await expectLater(
      backups.backupMnemonic(walletId: 'wallet-1', mnemonic: phrase, password: _password),
      throwsA(isA<InvalidMnemonicException>()),
    );
    expect(store.writes, 0);
  });

  test('tells a wrong password apart', () async {
    await backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password);

    await expectLater(
      backups.restoreMnemonic('wallet-1', password: 'not the password'),
      throwsA(isA<WrongBackupPasswordException>()),
    );
    expect(await backups.verifyPassword('wallet-1', password: 'not the password'), isFalse);
    expect(await backups.verifyPassword('wallet-1', password: _password), isTrue);
  });

  test('detects a mnemonic that no longer derives the backed-up wallet', () async {
    await backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password);
    platform.addressSalt = 'different derivation';

    await expectLater(
      backups.restoreMnemonic('wallet-1', password: _password),
      throwsA(isA<BackupIntegrityException>()),
    );
  });

  test('restores a wallet with an optional BIP39 passphrase', () async {
    await backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password);

    final wallet = await backups.restoreWallet(
      'wallet-1',
      password: _password,
      bip39Passphrase: 'extra',
    );

    expect(await wallet.getMnemonic(), mnemonic12);
    expect(platform.importedPassphrases.last, 'extra');
    await wallet.dispose();
    expect(platform.wallets, isEmpty);
  });

  test('backs up an open wallet without disposing it', () async {
    final wallet = await WalletCore(platform: platform).importWallet(mnemonic: mnemonic24);

    await backups.backupWallet(walletId: 'wallet-2', wallet: wallet, password: _password);

    expect(wallet.isDisposed, isFalse);
    expect(await backups.restoreMnemonic('wallet-2', password: _password), mnemonic24);
    await wallet.dispose();
  });

  test('lists restorable wallets and explains the others', () async {
    final cloud = backups.cloud;
    await backups.backupMnemonic(
      walletId: 'wallet-1',
      mnemonic: mnemonic12,
      password: _password,
      label: 'Main',
    );
    await cloud.backup(
      await WalletBackup.create(
        walletId: 'legacy',
        encryptedKeystore: <String, Object?>{'version': 3},
      ),
    );
    final broken = await backups.backupMnemonic(
      walletId: 'broken',
      mnemonic: mnemonic12,
      password: _password,
    );
    store.files[broken.name] = Uint8List.fromList(utf8.encode('{}'));

    final listed = {for (final wallet in await backups.listRestorable()) wallet.walletId: wallet};

    expect(listed.keys, unorderedEquals(<String>['wallet-1', 'legacy', 'broken']));
    expect(listed['wallet-1']!.isRestorable, isTrue);
    expect(listed['wallet-1']!.label, 'Main');
    expect(listed['legacy']!.error, isA<BackupFormatException>());
    expect(listed['broken']!.isRestorable, isFalse);
  });

  test('reads several wallets at once without reordering them', () async {
    for (var index = 0; index < 9; index++) {
      await backups.backupMnemonic(
        walletId: 'wallet-$index',
        mnemonic: mnemonic12,
        password: _password,
      );
    }
    store
      ..peakConcurrentReads = 0
      ..readDelay = const Duration(milliseconds: 20);

    final listed = await backups.listRestorable();

    expect(listed.map((wallet) => wallet.walletId), <String>[
      for (var index = 0; index < 9; index++) 'wallet-$index',
    ]);
    expect(listed.every((wallet) => wallet.isRestorable), isTrue);
    // Overlapping reads, but never an unbounded fan-out at the provider.
    expect(store.peakConcurrentReads, greaterThan(1));
    expect(store.peakConcurrentReads, lessThanOrEqualTo(4));
  });

  test('changes the password and keeps the label', () async {
    await backups.backupMnemonic(
      walletId: 'wallet-1',
      mnemonic: mnemonic12,
      password: _password,
      label: 'Main',
    );

    await backups.changePassword(
      'wallet-1',
      currentPassword: _password,
      newPassword: 'a brand new password',
    );

    expect(await backups.verifyPassword('wallet-1', password: _password), isFalse);
    expect(await backups.restoreMnemonic('wallet-1', password: 'a brand new password'), mnemonic12);
    expect((await backups.listRestorable()).single.label, 'Main');
  });

  test('writes nothing when the current password is wrong', () async {
    await backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password);
    final writes = store.writes;

    await expectLater(
      backups.changePassword(
        'wallet-1',
        currentPassword: 'not the password',
        newPassword: 'a brand new password',
      ),
      throwsA(isA<WrongBackupPasswordException>()),
    );
    expect(store.writes, writes);
    expect(await backups.verifyPassword('wallet-1', password: _password), isTrue);
  });

  test('says when an upload could not be verified', () async {
    await backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password);
    final old = Uint8List.fromList(store.files.values.single);
    store.onRead = (_, _) => old;

    await expectLater(
      backups.changePassword(
        'wallet-1',
        currentPassword: _password,
        newPassword: 'a brand new password',
      ),
      throwsA(
        isA<CloudStorageException>().having((e) => e.message, 'message', contains('replaced')),
      ),
    );
    store.onRead = null;
    expect(await backups.verifyPassword('wallet-1', password: 'a brand new password'), isTrue);
  });

  test('fails when the cloud returns something other than what was written', () async {
    final stale = await backups.cloud.backup(
      await WalletBackup.create(walletId: 'wallet-1', encryptedKeystore: <String, Object?>{'v': 1}),
    );
    final staleBytes = store.files[stale.name]!;
    store.onRead = (_, _) => staleBytes;

    await expectLater(
      backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password),
      throwsA(isA<CloudStorageException>()),
    );
  });

  test('maps an unusable Wallet Core to WalletCoreUnavailableException', () async {
    platform.failWithCode = 'native_library_unavailable';

    expect(await backups.isWalletCoreAvailable(), isFalse);
    await expectLater(
      backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password),
      throwsA(isA<WalletCoreUnavailableException>()),
    );
  });

  for (final (name, error) in <(String, Object)>[
    ('a channel error', const WalletCoreException('channel-error', 'No host.')),
    ('a missing plugin', MissingPluginException('No implementation.')),
  ]) {
    test('maps $name to WalletCoreUnavailableException', () async {
      platform.failWith = error;

      await expectLater(
        backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password),
        throwsA(isA<WalletCoreUnavailableException>()),
      );
    });
  }

  test('keeps StateError for a disposed wallet', () async {
    final wallet = await WalletCore(platform: platform).importWallet(mnemonic: mnemonic12);
    await wallet.dispose();

    await expectLater(
      backups.backupWallet(walletId: 'wallet-1', wallet: wallet, password: _password),
      throwsStateError,
    );
  });

  test('reports Wallet Core as unavailable when no plugin is registered', () async {
    final unregistered = create(walletCore: WalletCore());

    expect(await unregistered.isWalletCoreAvailable(), isFalse);
    await expectLater(
      unregistered.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password),
      throwsA(isA<WalletCoreUnavailableException>()),
    );
  });

  test('never puts the mnemonic or password in an error', () async {
    await backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: _password);
    final errors = <Object>[];
    Future<void> capture(Future<Object?> Function() action) async {
      try {
        await action();
      } on Object catch (error) {
        errors.add(error);
      }
    }

    await capture(() => backups.restoreMnemonic('wallet-1', password: 'wrong password!'));
    await capture(
      () => backups.backupMnemonic(
        walletId: 'wallet-1',
        mnemonic: '$mnemonic12 x',
        password: _password,
      ),
    );
    await capture(
      () => backups.backupMnemonic(walletId: 'wallet-1', mnemonic: mnemonic12, password: 'abandon'),
    );
    platform.addressSalt = 'drift';
    await capture(() => backups.restoreMnemonic('wallet-1', password: _password));

    expect(errors, hasLength(4));
    for (final error in errors) {
      final text = '$error ${error is WalletCloudBackupException ? error.cause : ''}';
      expect(text, isNot(contains('abandon')));
      expect(text, isNot(contains(_password)));
    }
  });

  test('requires a minimum password length of at least 8', () {
    expect(
      () => MnemonicCloudBackup(
        WalletCloudBackup.withStore(store),
        walletCore: WalletCore(platform: platform),
        minPasswordLength: 6,
      ),
      throwsArgumentError,
    );
  });
}
