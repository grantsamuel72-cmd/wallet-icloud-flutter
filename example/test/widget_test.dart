import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/main.dart';
import 'package:wallet_core/wallet_core.dart';
import 'package:wallet_core_platform_interface/wallet_core_platform_interface.dart';

const _demoMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

/// Accepts only the demo vector; the address stands in for Wallet Core's.
class _FakeWalletCore extends WalletCorePlatform {
  final Map<int, String> _wallets = <int, String>{};
  int _next = 0;

  @override
  Future<bool> isValidMnemonic(String mnemonic) async =>
      mnemonic == _demoMnemonic;

  @override
  Future<int> importWallet(String mnemonic, String passphrase) async {
    _wallets[++_next] = mnemonic;
    return _next;
  }

  @override
  Future<String> getAddress(
    int walletId,
    int coin,
    String? derivationPath,
  ) async => '0xFAKE';

  @override
  Future<void> deleteWallet(int walletId) async => _wallets.remove(walletId);
}

const _cheap = BackupKdfParameters(
  memoryKiB: 64,
  iterations: 1,
  parallelism: 1,
);

Widget _app() => MaterialApp(
  home: BackupDemoPage(
    createBackups: (cloud) => MnemonicCloudBackup.forTesting(
      cloud,
      walletCore: WalletCore(platform: _FakeWalletCore()),
      kdf: _cheap,
      minimumKdf: _cheap,
    ),
  ),
);

/// Lets real asynchronous work (the Argon2id isolate) finish until [finder] appears.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(finder, findsOneWidget);
}

Finder _field(String label) => find.widgetWithText(TextField, label);

void main() {
  testWidgets('starts in demo mode with the demo mnemonic', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('演示模式：备份只保存在内存里。'), findsOneWidget);
    expect(find.text('连接云盘'), findsNothing);
    expect(find.text(_demoMnemonic), findsOneWidget);
  });

  testWidgets('shows the cloud connect button outside demo mode', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.text('连接云盘'), findsOneWidget);
  });

  testWidgets('explains a password that is too short', (tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(_field('备份密码（至少 8 个字符）'), 'short');
    await tester.tap(find.text('备份'));
    await _waitFor(tester, find.text('密码至少 8 个字符。'));
  });

  testWidgets('backs up, lists and restores a wallet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.enterText(_field('备份密码（至少 8 个字符）'), 'correct horse battery');

    await tester.tap(find.text('备份'));
    await _waitFor(tester, find.text('已加密并上传，已回读校验。'));
    expect(find.text('主钱包'), findsWidgets, reason: 'the label is listed');

    await tester.tap(find.text('恢复'));
    await _waitFor(tester, find.text('恢复成功，ETH 地址：0xFAKE'));
  });

  testWidgets('shows what is actually in the container', (tester) async {
    await tester.pumpWidget(_app());
    await tester.enterText(_field('备份密码（至少 8 个字符）'), 'correct horse battery');
    await tester.tap(find.text('备份'));
    await _waitFor(tester, find.text('已加密并上传，已回读校验。'));

    await tester.tap(find.text('诊断'));
    await _waitFor(tester, find.text('容器里有 1 个文件。'));

    expect(find.text('连接状态：可用'), findsOneWidget);
    expect(
      find.text('wallet-64656d6f2d77616c6c6574.json'),
      findsOneWidget,
      reason: 'the real file name, so a hidden backup can still be verified',
    );
  });

  testWidgets('tells the user when the password is wrong', (tester) async {
    await tester.pumpWidget(_app());
    await tester.enterText(_field('备份密码（至少 8 个字符）'), 'correct horse battery');
    await tester.tap(find.text('备份'));
    await _waitFor(tester, find.text('已加密并上传，已回读校验。'));

    await tester.enterText(_field('备份密码（至少 8 个字符）'), 'not the password');
    await tester.tap(find.text('恢复'));
    await _waitFor(tester, find.text('密码不对，请重试。'));
  });
}
