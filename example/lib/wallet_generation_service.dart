import 'dart:math';

import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_core/wallet_core.dart';

/// A newly generated wallet whose TRON address receives TRC20 tokens.
class GeneratedTronWallet {
  /// Creates generated wallet details for the current screen.
  const GeneratedTronWallet({
    required this.walletId,
    required this.mnemonic,
    required this.tronAddress,
  });

  /// A random public identifier used as the backup file key.
  final String walletId;

  /// The BIP39 recovery phrase, which must be kept secret.
  final String mnemonic;

  /// The TRON address at Wallet Core's default derivation path.
  final String tronAddress;

  @override
  String toString() => 'GeneratedTronWallet(<redacted>)';
}

/// A TRON private key exported temporarily for an explicit reveal action.
class TronPrivateKeyExport {
  /// Creates the export for [tronAddress].
  const TronPrivateKeyExport({
    required this.tronAddress,
    required this.privateKeyHex,
  });

  /// The address controlled by [privateKeyHex].
  final String tronAddress;

  /// The 32-byte private key encoded as lowercase hexadecimal.
  final String privateKeyHex;

  @override
  String toString() => 'TronPrivateKeyExport(<redacted>)';
}

/// Generates a fresh mnemonic and derives its TRON address with Wallet Core.
class WalletGenerationService {
  /// Creates a generator with an optional Wallet Core implementation.
  WalletGenerationService({WalletCore? walletCore, Random? random})
    : _walletCore = walletCore ?? WalletCore(),
      _random = random ?? Random.secure();

  final WalletCore _walletCore;
  final Random _random;

  /// Creates a new 12-word wallet and releases its native handle.
  Future<GeneratedTronWallet> generate() async {
    final wallet = await _walletCore.createWallet(strength: 128);
    try {
      final mnemonic = await wallet.getMnemonic();
      final tronAddress = await wallet.getAddress(CoinType.tron);
      final idBytes = List<int>.generate(16, (_) => _random.nextInt(256));
      final walletId =
          'wallet-${idBytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join()}';
      return GeneratedTronWallet(
        walletId: walletId,
        mnemonic: mnemonic,
        tronAddress: tronAddress,
      );
    } finally {
      await wallet.dispose();
    }
  }

  /// Exports the TRON private key derived from [mnemonic] for immediate display.
  ///
  /// The native wallet handle and temporary key bytes are released before this
  /// returns. The returned hexadecimal string must never be logged or backed up.
  Future<TronPrivateKeyExport> exportTronPrivateKey(String mnemonic) async {
    if (!await _walletCore.isValidMnemonic(mnemonic)) {
      throw const InvalidMnemonicException();
    }
    final wallet = await _walletCore.importWallet(mnemonic: mnemonic);
    try {
      final address = await wallet.getAddress(CoinType.tron);
      final key = await wallet.getPrivateKey(CoinType.tron);
      try {
        if (key.length != 32) {
          throw const WalletCloudBackupException(
            'Wallet Core returned an invalid TRON key.',
          );
        }
        final hex = key
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join();
        return TronPrivateKeyExport(tronAddress: address, privateKeyHex: hex);
      } finally {
        key.fillRange(0, key.length, 0);
      }
    } finally {
      await wallet.dispose();
    }
  }
}
