import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/data/wallet_database.dart';
import 'package:wallet_cloud_backup_example/data/wallet_repository.dart';
import 'package:wallet_cloud_backup_example/data/wallet_secret_store.dart';
import 'package:wallet_cloud_backup_example/memory_backup_store.dart';
import 'package:wallet_cloud_backup_example/ui/wallet_manager_page.dart';
import 'package:wallet_cloud_backup_example/ui/wallet_manager_view_model.dart';
import 'package:wallet_core/wallet_core.dart';

import 'support/fake_wallet_core.dart';

class _Secrets implements WalletSecretStore {
  final values = <String, String>{};

  @override
  Future<void> write(String reference, String secret) async {
    values[reference] = secret;
  }

  @override
  Future<String?> read(String reference) async => values[reference];

  @override
  Future<bool> contains(String reference) async =>
      values.containsKey(reference);

  @override
  Future<void> delete(String reference) async {
    values.remove(reference);
  }
}

void main() {
  testWidgets('creates a local HD wallet and shows its mnemonic once', (
    tester,
  ) async {
    final db = WalletDatabase(NativeDatabase.memory());
    final secrets = _Secrets();
    final core = WalletCore(platform: FakeWalletCore());
    final model = WalletManagerViewModel(
      WalletRepository(
        database: db,
        secrets: secrets,
        core: core,
        backups: MnemonicCloudBackup.forTesting(
          WalletCloudBackup.withStore(MemoryBackupStore()),
          walletCore: core,
          kdf: const BackupKdfParameters(
            memoryKiB: 64,
            iterations: 1,
            parallelism: 1,
          ),
          minimumKdf: const BackupKdfParameters(
            memoryKiB: 64,
            iterations: 1,
            parallelism: 1,
          ),
        ),
        random: Random(1),
      ),
    );
    addTearDown(() async {
      model.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      MaterialApp(home: WalletManagerPage(viewModel: model)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '钱包名称'), '我的钱包');
    await tester.tap(find.text('保存钱包'));
    await tester.pumpAndSettle();

    expect(find.text('请离线抄写助记词'), findsOneWidget);
    expect(find.text(firstGeneratedMnemonic), findsOneWidget);
    await tester.tap(find.text('我已妥善记录'));
    await tester.pumpAndSettle();
    expect(find.text(firstGeneratedMnemonic), findsNothing);
    expect(secrets.values.values.single, firstGeneratedMnemonic);
    expect(model.wallets.single.addresses.length, 3);
    expect(find.widgetWithText(ExpansionTile, '我的钱包'), findsOneWidget);
  });
}
