import 'package:wallet_core/wallet_core.dart';

enum WalletKind {
  hd,
  importedKey,
  watchOnly;

  String get databaseValue => switch (this) {
    hd => 'hd',
    importedKey => 'imported_key',
    watchOnly => 'watch_only',
  };

  static WalletKind fromDatabase(String value) =>
      WalletKind.values.firstWhere((kind) => kind.databaseValue == value);
}

enum WalletChain {
  evm('EVM（ETH / Polygon / BSC）', 'evm', CoinType.ethereum, 'eip155:1', 'hex'),
  tron('TRON', 'tron', CoinType.tron, 'tron:mainnet', 'base58check'),
  bitcoin(
    'Bitcoin',
    'bitcoin',
    CoinType.bitcoin,
    'bip122:000000000019d6689c085ae165831e93',
    'auto',
  );

  const WalletChain(
    this.label,
    this.family,
    this.coinType,
    this.primaryNetworkId,
    this.addressFormat,
  );

  final String label;
  final String family;
  final CoinType coinType;
  final String primaryNetworkId;
  final String addressFormat;

  List<(String, String)> get networks => switch (this) {
    WalletChain.evm => const <(String, String)>[
      ('eip155:1', 'Ethereum'),
      ('eip155:137', 'Polygon'),
      ('eip155:56', 'BNB Smart Chain'),
    ],
    WalletChain.tron => const <(String, String)>[('tron:mainnet', 'TRON')],
    WalletChain.bitcoin => const <(String, String)>[
      ('bip122:000000000019d6689c085ae165831e93', 'Bitcoin'),
    ],
  };
}

class StoredAddress {
  const StoredAddress({
    required this.chain,
    required this.address,
    required this.path,
    required this.index,
  });

  final WalletChain chain;
  final String address;
  final String path;
  final int? index;
}

class StoredWallet {
  const StoredWallet({
    required this.id,
    required this.name,
    required this.kind,
    required this.state,
    required this.backupState,
    required this.addresses,
  });

  final String id;
  final String name;
  final WalletKind kind;
  final String state;
  final String backupState;
  final List<StoredAddress> addresses;
}
