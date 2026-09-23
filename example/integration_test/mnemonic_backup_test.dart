import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/memory_backup_store.dart';
import 'package:wallet_core/wallet_core.dart';

// BIP39 test vector and its Ethereum address at m/44'/60'/0'/0/0.
const _mnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const _ethereumAddress = '0x9858EfFD232B4033E47d90003D41EC34EcaEda94';
const _password = 'integration test password';

/// Runs on a real device or simulator: real Wallet Core, real Argon2id
/// parameters, in-memory storage so no cloud account is needed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MnemonicCloudBackup backups;

  setUp(
    () => backups = MnemonicCloudBackup(
      WalletCloudBackup.withStore(MemoryBackupStore()),
    ),
  );

  testWidgets('Wallet Core native library is available', (_) async {
    expect(await backups.isWalletCoreAvailable(), isTrue);
  });

  testWidgets('backs up and restores the BIP39 test vector', (_) async {
    final clock = Stopwatch()..start();
    await backups.backupMnemonic(
      walletId: 'vector',
      mnemonic: _mnemonic,
      password: _password,
    );
    final backupTime = clock.elapsed;

    clock.reset();
    final wallet = await backups.restoreWallet('vector', password: _password);
    final restoreTime = clock.elapsed;
    try {
      expect(await wallet.getAddress(CoinType.ethereum), _ethereumAddress);
      expect(await wallet.getMnemonic(), _mnemonic);
    } finally {
      await wallet.dispose();
    }
    debugPrint(
      'wallet_cloud_backup timing: backup ${backupTime.inMilliseconds} ms, '
      'restore ${restoreTime.inMilliseconds} ms',
    );
  });

  testWidgets('rejects a wrong password', (_) async {
    await backups.backupMnemonic(
      walletId: 'vector',
      mnemonic: _mnemonic,
      password: _password,
    );

    await expectLater(
      backups.restoreMnemonic('vector', password: 'not the password'),
      throwsA(isA<WrongBackupPasswordException>()),
    );
  });

  testWidgets('lets Wallet Core reject a mnemonic with a bad checksum', (
    _,
  ) async {
    await expectLater(
      backups.backupMnemonic(
        walletId: 'vector',
        mnemonic: _mnemonic.replaceFirst('about', 'abandon'),
        password: _password,
      ),
      throwsA(isA<InvalidMnemonicException>()),
    );
  });
}
