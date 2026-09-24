import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/main.dart';
import 'package:wallet_core/wallet_core.dart';
import 'package:wallet_cloud_backup_example/wallet_generation_service.dart';

import 'support/fake_wallet_core.dart';

const _cheap = BackupKdfParameters(
  memoryKiB: 64,
  iterations: 1,
  parallelism: 1,
);

Widget _app({FakeWalletCore? platform}) {
  final core = WalletCore(platform: platform ?? FakeWalletCore());
  return MaterialApp(
    home: BackupDemoPage(
      walletGenerator: WalletGenerationService(
        walletCore: core,
        random: Random(1),
      ),
      createBackups: (cloud) => MnemonicCloudBackup.forTesting(
        cloud,
        walletCore: core,
        kdf: _cheap,
        minimumKdf: _cheap,
      ),
    ),
  );
}

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
Finder get _listScrollable => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Future<void> _tapRestore(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -350));
  await tester.pump();
  await tester.tap(find.text('恢复'));
  await tester.pump();
  for (
    var i = 0;
    i < 300 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(find.byType(LinearProgressIndicator), findsNothing);
  await tester.drag(find.byType(ListView), const Offset(0, 500));
  await tester.pump();
}

void main() {
  testWidgets('starts in demo mode with the demo mnemonic', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('演示模式：备份只保存在内存里。'), findsOneWidget);
    expect(find.text('连接云盘'), findsNothing);
    expect(find.text(demoMnemonic), findsOneWidget);
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
    await _waitFor(tester, find.text('已加密并上传当前 TRC20 地址，已回读校验。'));
    expect(find.text('主钱包'), findsWidgets, reason: 'the label is listed');

    await _tapRestore(tester);
    await _waitFor(tester, find.text('恢复成功，TRC20 地址：TDEMO'));
  });

  testWidgets('shows what is actually in the container', (tester) async {
    await tester.pumpWidget(_app());
    await tester.enterText(_field('备份密码（至少 8 个字符）'), 'correct horse battery');
    await tester.tap(find.text('备份'));
    await _waitFor(tester, find.text('已加密并上传当前 TRC20 地址，已回读校验。'));

    await tester.tap(find.text('诊断'));
    await _waitFor(tester, find.text('容器里有 1 个文件。'));

    await tester.scrollUntilVisible(
      find.text('连接状态：可用'),
      200,
      scrollable: _listScrollable,
    );
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
    await _waitFor(tester, find.text('已加密并上传当前 TRC20 地址，已回读校验。'));

    await tester.enterText(_field('备份密码（至少 8 个字符）'), 'not the password');
    await _tapRestore(tester);
    await _waitFor(tester, find.text('密码不对，请重试。'));
  });

  testWidgets(
    'generates and regenerates a TRC20 wallet without overwriting its backup id',
    (tester) async {
      await tester.pumpWidget(_app());

      await tester.tap(find.text('生成 TRC20 钱包'));
      await _waitFor(tester, find.text('已生成 TRC20 钱包，请妥善保管助记词。'));
      expect(find.text(firstGeneratedMnemonic), findsOneWidget);
      expect(find.text('TRC20 地址：TGENERATED1'), findsOneWidget);
      final firstId = tester
          .widget<TextField>(_field('钱包 ID'))
          .controller!
          .text;

      await tester.tap(find.text('重新生成'));
      await _waitFor(tester, find.text('TRC20 地址：TGENERATED2'));
      expect(find.text(secondGeneratedMnemonic), findsOneWidget);
      expect(
        tester.widget<TextField>(_field('钱包 ID')).controller!.text,
        isNot(firstId),
      );
    },
  );

  testWidgets('backs up the generated address and restores that address', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('生成 TRC20 钱包'));
    await _waitFor(tester, find.text('TRC20 地址：TGENERATED1'));
    await tester.enterText(_field('备份密码（至少 8 个字符）'), 'correct horse battery');

    await tester.tap(find.text('备份'));
    await _waitFor(tester, find.text('已加密并上传当前 TRC20 地址，已回读校验。'));
    await tester.enterText(_field('助记词（示例为公开测试向量）'), '');
    await tester.pump();
    expect(find.text('TRC20 地址：TGENERATED1'), findsNothing);
    await _tapRestore(tester);
    await _waitFor(tester, find.text('恢复成功，TRC20 地址：TGENERATED1'));
    expect(find.text(firstGeneratedMnemonic), findsOneWidget);
    expect(find.text('TRC20 地址：TGENERATED1'), findsOneWidget);
  });

  testWidgets(
    'confirms before revealing the current TRON key and hides it on close',
    (tester) async {
      final platform = FakeWalletCore();
      await tester.pumpWidget(_app(platform: platform));
      await tester.tap(find.text('生成 TRC20 钱包'));
      await _waitFor(tester, find.text('TRC20 地址：TGENERATED1'));

      await tester.tap(find.text('查看私钥'));
      await tester.pumpAndSettle();
      expect(find.text('查看 TRON 私钥？'), findsOneWidget);
      expect(platform.privateKeyExports, 0);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tron-private-key')), findsNothing);

      await tester.tap(find.text('查看私钥'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续查看'));
      await _waitFor(tester, find.byKey(const Key('tron-private-key')));
      expect(find.text('11' * 32), findsOneWidget);
      expect(find.text('地址：TGENERATED1'), findsOneWidget);
      expect(platform.privateKeyExports, 1);

      await tester.tap(find.text('关闭'));
    await _waitFor(tester, find.text('私钥已隐藏。'));
    expect(find.byKey(const Key('tron-private-key')), findsNothing);
    expect(find.text('11' * 32), findsNothing);

    await tester.tap(find.text('重新生成'));
    await _waitFor(tester, find.text('TRC20 地址：TGENERATED2'));
    await tester.tap(find.text('查看私钥'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续查看'));
    await _waitFor(tester, find.text('22' * 32));
    expect(find.text('11' * 32), findsNothing);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    },
  );
}
