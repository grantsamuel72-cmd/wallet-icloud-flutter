import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/wallet_generation_service.dart';
import 'package:wallet_core/wallet_core.dart';

import 'support/fake_wallet_core.dart';

void main() {
  test(
    'generates distinct recovery phrases and TRON addresses, releasing wallet handles',
    () async {
      final platform = FakeWalletCore();
      final generator = WalletGenerationService(
        walletCore: WalletCore(platform: platform),
        random: Random(7),
      );

      final first = await generator.generate();
      final second = await generator.generate();

      expect(first.mnemonic, firstGeneratedMnemonic);
      expect(first.tronAddress, 'TGENERATED1');
      expect(second.mnemonic, secondGeneratedMnemonic);
      expect(second.tronAddress, 'TGENERATED2');
      expect(second.walletId, isNot(first.walletId));
      expect(platform.wallets, isEmpty);
      expect(first.toString(), isNot(contains(first.mnemonic)));
    },
  );

  test(
    'exports only the current TRON key and wipes native key bytes',
    () async {
      final platform = FakeWalletCore();
      final generator = WalletGenerationService(
        walletCore: WalletCore(platform: platform),
      );

      final export = await generator.exportTronPrivateKey(
        firstGeneratedMnemonic,
      );

      expect(export.tronAddress, 'TGENERATED1');
      expect(export.privateKeyHex, '11' * 32);
      expect(export.toString(), isNot(contains(export.privateKeyHex)));
      expect(platform.privateKeyExports, 1);
      expect(platform.lastPrivateKeyBytes, everyElement(0));
      expect(platform.wallets, isEmpty);
    },
  );

  test('rejects an invalid phrase without exporting a key', () async {
    final platform = FakeWalletCore();
    final generator = WalletGenerationService(
      walletCore: WalletCore(platform: platform),
    );

    await expectLater(
      generator.exportTronPrivateKey('not a BIP39 phrase'),
      throwsA(isA<InvalidMnemonicException>()),
    );
    expect(platform.privateKeyExports, 0);
    expect(platform.wallets, isEmpty);
  });
}
