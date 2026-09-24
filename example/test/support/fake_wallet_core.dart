import 'dart:typed_data';

import 'package:wallet_core_platform_interface/wallet_core_platform_interface.dart';

const demoMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const firstGeneratedMnemonic =
    'legal winner thank year wave sausage worth useful legal winner thank yellow';
const secondGeneratedMnemonic =
    'letter advice cage absurd amount doctor acoustic avoid letter advice cage above';

class FakeWalletCore extends WalletCorePlatform {
  final Map<int, String> wallets = <int, String>{};
  int nextId = 0;
  int generatedCount = 0;
  int privateKeyExports = 0;
  Uint8List? lastPrivateKeyBytes;

  @override
  Future<int> createWallet(int strength, String passphrase) async {
    if (strength != 128 || passphrase.isNotEmpty) {
      throw ArgumentError('Unexpected wallet generation parameters.');
    }
    final mnemonic = generatedCount++ == 0
        ? firstGeneratedMnemonic
        : secondGeneratedMnemonic;
    wallets[++nextId] = mnemonic;
    return nextId;
  }

  @override
  Future<bool> isValidMnemonic(String mnemonic) async =>
      mnemonic == demoMnemonic ||
      mnemonic == firstGeneratedMnemonic ||
      mnemonic == secondGeneratedMnemonic;

  @override
  Future<int> importWallet(String mnemonic, String passphrase) async {
    wallets[++nextId] = mnemonic;
    return nextId;
  }

  @override
  Future<String> getMnemonic(int walletId) async => wallets[walletId]!;

  @override
  Future<String> getAddress(
    int walletId,
    int coin,
    String? derivationPath,
  ) async {
    if (coin == CoinType.tron.value) {
      return switch (wallets[walletId]) {
        firstGeneratedMnemonic => 'TGENERATED1',
        secondGeneratedMnemonic => 'TGENERATED2',
        _ => 'TDEMO',
      };
    }
    return '0xFAKE';
  }

  @override
  Future<Uint8List> getPrivateKey(
    int walletId,
    int coin,
    String? derivationPath,
  ) async {
    if (coin != CoinType.tron.value || derivationPath != null) {
      throw ArgumentError('Expected the default TRON derivation path.');
    }
    privateKeyExports++;
    final key = Uint8List.fromList(
      List<int>.filled(
        32,
        wallets[walletId] == firstGeneratedMnemonic ? 0x11 : 0x22,
      ),
    );
    lastPrivateKeyBytes = key;
    return key;
  }

  @override
  Future<void> deleteWallet(int walletId) async {
    wallets.remove(walletId);
  }
}
