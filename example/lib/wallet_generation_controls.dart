import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Controls for generating a wallet and displaying its TRC20 receive address.
class WalletGenerationControls extends StatelessWidget {
  /// Creates generation controls with the current [tronAddress].
  const WalletGenerationControls({
    super.key,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onViewPrivateKey,
    required this.tronAddress,
  });

  /// Generates a new wallet.
  final VoidCallback? onGenerate;

  /// Replaces the current wallet with a newly generated one.
  final VoidCallback? onRegenerate;

  /// Requests an explicit reveal of the current TRON private key.
  final VoidCallback? onViewPrivateKey;

  /// The current TRON address, or `null` before one is derived.
  final String? tronAddress;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          FilledButton(onPressed: onGenerate, child: const Text('生成 TRC20 钱包')),
          OutlinedButton(onPressed: onRegenerate, child: const Text('重新生成')),
          OutlinedButton(
            onPressed: onViewPrivateKey,
            child: const Text('查看私钥'),
          ),
        ],
      ),
      if (tronAddress != null) ...<Widget>[
        const SizedBox(height: 8),
        SelectableText('TRC20 地址：$tronAddress', key: const Key('tron-address')),
      ],
    ],
  );
}

@Preview(name: 'TRC20 钱包生成', size: Size(420, 180))
Widget walletGenerationControlsPreview() => const MaterialApp(
  home: Scaffold(
    body: Padding(
      padding: EdgeInsets.all(16),
      child: WalletGenerationControls(
        onGenerate: null,
        onRegenerate: null,
        onViewPrivateKey: null,
        tronAddress: 'TQxYwSzz48X8dq7Y4Qb1tkKTRsYzVFbZTP',
      ),
    ),
  ),
);
