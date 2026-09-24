import 'dart:convert';

import 'package:wallet_core_platform_interface/wallet_core_platform_interface.dart';

/// Valid 12-word BIP39 test vector.
const String mnemonic12 =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

/// Valid 24-word BIP39 test vector.
const String mnemonic24 =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon art';

/// Wallet Core stand-in: accepts the two test vectors and derives a
/// deterministic fake address from mnemonic and passphrase.
class FakeWalletCorePlatform extends WalletCorePlatform {
  final Map<int, ({String mnemonic, String passphrase})> wallets =
      <int, ({String mnemonic, String passphrase})>{};

  /// When set, every call fails with this Wallet Core error code.
  String? failWithCode;

  /// When set, every call throws this instead.
  Object? failWith;

  /// When set, addresses are derived from this instead of the real phrase.
  String? addressSalt;

  /// When set, only TRON address derivation changes.
  String? tronAddressSalt;

  int _nextId = 0;

  /// Passphrases passed to [importWallet], in order.
  final List<String> importedPassphrases = <String>[];

  void _maybeFail() {
    if (failWith case final error?) {
      throw error;
    }
    if (failWithCode case final code?) {
      throw WalletCoreException(code, 'Fake failure.');
    }
  }

  static bool _isValid(String mnemonic) => mnemonic == mnemonic12 || mnemonic == mnemonic24;

  @override
  Future<bool> isValidMnemonic(String mnemonic) async {
    _maybeFail();
    return _isValid(mnemonic);
  }

  @override
  Future<int> importWallet(String mnemonic, String passphrase) async {
    _maybeFail();
    if (!_isValid(mnemonic)) {
      throw const WalletCoreException('invalid_mnemonic', 'Invalid mnemonic.');
    }
    importedPassphrases.add(passphrase);
    wallets[++_nextId] = (mnemonic: mnemonic, passphrase: passphrase);
    return _nextId;
  }

  @override
  Future<String> getMnemonic(int walletId) async {
    _maybeFail();
    return wallets[walletId]!.mnemonic;
  }

  @override
  Future<String> getAddress(int walletId, int coin, String? derivationPath) async {
    _maybeFail();
    final wallet = wallets[walletId]!;
    final salt = coin == CoinType.tron.value ? tronAddressSalt ?? addressSalt : addressSalt;
    final source = '${salt ?? ''}|${wallet.mnemonic}|${wallet.passphrase}|$coin';
    return '0x${base64Url.encode(utf8.encode(source)).hashCode.toRadixString(16)}';
  }

  @override
  Future<void> deleteWallet(int walletId) async {
    wallets.remove(walletId);
  }
}
