import 'package:flutter/material.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/data/wallet_database.dart';
import 'package:wallet_cloud_backup_example/data/wallet_repository.dart';
import 'package:wallet_cloud_backup_example/data/wallet_secret_store.dart';
import 'package:wallet_cloud_backup_example/domain/wallet_models.dart';
import 'package:wallet_cloud_backup_example/ui/wallet_manager_view_model.dart';
import 'package:wallet_core/wallet_core.dart';

class WalletManagerPage extends StatefulWidget {
  const WalletManagerPage({super.key, this.viewModel});

  final WalletManagerViewModel? viewModel;

  @override
  State<WalletManagerPage> createState() => _WalletManagerPageState();
}

class _WalletManagerPageState extends State<WalletManagerPage> {
  final _name = TextEditingController();
  final _mnemonic = TextEditingController();
  final _privateKey = TextEditingController();
  final _watchAddress = TextEditingController();
  final _backupPassword = TextEditingController();
  WalletKind _kind = WalletKind.hd;
  WalletChain _watchChain = WalletChain.evm;
  late final WalletDatabase? _ownedDatabase;
  late final WalletManagerViewModel _model;

  @override
  void initState() {
    super.initState();
    _ownedDatabase = widget.viewModel == null ? WalletDatabase() : null;
    _model =
        widget.viewModel ??
        WalletManagerViewModel(
          WalletRepository(
            database: _ownedDatabase!,
            secrets: SecureWalletSecretStore(),
            core: WalletCore(),
            backups: MnemonicCloudBackup(
              WalletCloudBackup(
                iCloud: const ICloudOptions(
                  containerId: 'iCloud.com.uux.dev',
                  folder: 'WalletBackups',
                ),
              ),
            ),
          ),
        );
    _model.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _mnemonic.dispose();
    _privateKey.dispose();
    _watchAddress.dispose();
    _backupPassword.dispose();
    if (widget.viewModel == null) _model.dispose();
    _ownedDatabase?.close();
    super.dispose();
  }

  Future<void> _create() async {
    switch (_kind) {
      case WalletKind.hd:
        final entered = _mnemonic.text.trim();
        final created = await _model.createHd(
          _name.text,
          mnemonic: entered.isEmpty ? null : entered,
        );
        _mnemonic.clear();
        if (!mounted || created?.mnemonic == null) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('请离线抄写助记词'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('丢失设备时，这组词是恢复钱包的根本凭证。不要截图或分享。'),
                const SizedBox(height: 12),
                SelectableText(created!.mnemonic!),
              ],
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('我已妥善记录'),
              ),
            ],
          ),
        );
      case WalletKind.importedKey:
        await _model.importPrivateKey(_name.text, _privateKey.text);
        _privateKey.clear();
      case WalletKind.watchOnly:
        await _model.addWatchOnly(_name.text, _watchChain, _watchAddress.text);
        _watchAddress.clear();
    }
  }

  Future<void> _addAddress(StoredWallet wallet) async {
    var chain = WalletChain.evm;
    final index = TextEditingController(text: '1');
    final result = await showDialog<(WalletChain, int)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加派生地址'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<WalletChain>(
                initialValue: chain,
                decoration: const InputDecoration(labelText: '链'),
                items: <DropdownMenuItem<WalletChain>>[
                  for (final choice in WalletChain.values)
                    DropdownMenuItem(value: choice, child: Text(choice.label)),
                ],
                onChanged: (value) =>
                    setDialogState(() => chain = value ?? chain),
              ),
              TextField(
                controller: index,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '地址索引（0 为首地址）'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(index.text);
                if (parsed == null) return;
                Navigator.pop(dialogContext, (chain, parsed));
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    index.dispose();
    if (result != null) {
      await _model.addAddress(wallet.id, result.$1, result.$2);
    }
  }

  Future<void> _delete(StoredWallet wallet) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('删除本地钱包 ${wallet.name}？'),
        content: Text(switch (wallet.kind) {
          WalletKind.hd => '本机助记词和地址记录将删除；已有云备份不会随之删除。请先确认备份密码可用。',
          WalletKind.importedKey => '导入的私钥没有云备份。删除本机数据前，请确认你另有原始私钥。',
          WalletKind.watchOnly => '本机的观察地址记录将删除。',
        }),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除本地数据'),
          ),
        ],
      ),
    );
    if (approved == true) await _model.deleteLocal(wallet.id);
  }

  Future<void> _backup(StoredWallet wallet) async {
    try {
      await _model.backup(wallet.id, _backupPassword.text);
    } finally {
      _backupPassword.clear();
    }
  }

  Future<void> _restore(RestorableWallet entry) async {
    try {
      await _model.restore(entry, _backupPassword.text);
    } finally {
      _backupPassword.clear();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _model,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('本地多链钱包')),
      body: AbsorbPointer(
        absorbing: _model.busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('创建或导入', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<WalletKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: '钱包类型'),
              items: const <DropdownMenuItem<WalletKind>>[
                DropdownMenuItem(value: WalletKind.hd, child: Text('HD 助记词钱包')),
                DropdownMenuItem(
                  value: WalletKind.importedKey,
                  child: Text('导入单独私钥'),
                ),
                DropdownMenuItem(
                  value: WalletKind.watchOnly,
                  child: Text('观察钱包'),
                ),
              ],
              onChanged: (value) => setState(() => _kind = value ?? _kind),
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '钱包名称'),
            ),
            if (_kind == WalletKind.hd)
              TextField(
                controller: _mnemonic,
                maxLines: 2,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                decoration: const InputDecoration(labelText: '助记词（留空则生成新钱包）'),
              ),
            if (_kind == WalletKind.importedKey)
              TextField(
                controller: _privateKey,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                decoration: const InputDecoration(labelText: '私钥（32 字节十六进制）'),
              ),
            if (_kind == WalletKind.watchOnly) ...<Widget>[
              DropdownButtonFormField<WalletChain>(
                initialValue: _watchChain,
                decoration: const InputDecoration(labelText: '链'),
                items: <DropdownMenuItem<WalletChain>>[
                  for (final chain in WalletChain.values)
                    DropdownMenuItem(value: chain, child: Text(chain.label)),
                ],
                onChanged: (value) =>
                    setState(() => _watchChain = value ?? _watchChain),
              ),
              TextField(
                controller: _watchAddress,
                decoration: const InputDecoration(labelText: '公开地址'),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton(onPressed: _create, child: const Text('保存钱包')),
            const SizedBox(height: 8),
            const Text(
              '本版使用空 BIP39 passphrase。地址配置仅存在本机，云端暂只备份 HD 助记词；钱包名称会以明文出现在当前备份格式中。',
            ),
            const Divider(height: 32),
            Text('本地钱包', style: Theme.of(context).textTheme.titleLarge),
            for (final wallet in _model.wallets) _walletTile(wallet),
            const Divider(height: 32),
            Text('云备份与恢复', style: Theme.of(context).textTheme.titleLarge),
            const Text(
              '为本地 HD 钱包备份到云盘前，请输入至少 8 位密码。密码不会保存在设备上；恢复后会重建默认 ETH、TRON、BTC 地址。',
            ),
            TextField(
              controller: _backupPassword,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: '备份密码'),
            ),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _model.connectCloud,
                  child: const Text('连接云盘'),
                ),
                OutlinedButton(
                  onPressed: _model.loadCloud,
                  child: const Text('列出云备份'),
                ),
              ],
            ),
            for (final entry in _model.cloudWallets)
              ListTile(
                title: Text(entry.label ?? entry.walletId),
                subtitle: Text(entry.error?.message ?? entry.walletId),
                trailing: entry.isRestorable
                    ? TextButton(
                        onPressed: () => _restore(entry),
                        child: const Text('恢复到本机'),
                      )
                    : null,
              ),
            if (_model.busy) const LinearProgressIndicator(),
            Text(_model.status),
          ],
        ),
      ),
    ),
  );

  Widget _walletTile(StoredWallet wallet) => Card(
    child: ExpansionTile(
      title: Text(wallet.name),
      subtitle: Text(
        '${wallet.kind.name} · ${wallet.state} · 云备份 ${switch (wallet.backupState) {
          'verified' => '已验证',
          'failed' => '失败',
          _ => '未备份',
        }}',
      ),
      children: <Widget>[
        for (final address in wallet.addresses)
          ListTile(
            dense: true,
            title: Text(address.chain.label),
            subtitle: SelectableText(
              '${address.address}\n${address.path.isEmpty ? '无派生路径' : address.path}',
            ),
          ),
        Wrap(
          spacing: 8,
          children: <Widget>[
            if (wallet.kind == WalletKind.hd && wallet.state == 'ready')
              TextButton(
                onPressed: () => _addAddress(wallet),
                child: const Text('添加地址'),
              ),
            TextButton(
              onPressed: () => _model.verify(wallet.id),
              child: const Text('验证'),
            ),
            if (wallet.kind == WalletKind.hd && wallet.state == 'ready')
              TextButton(
                onPressed: () => _backup(wallet),
                child: const Text('备份到云盘'),
              ),
            TextButton(
              onPressed: () => _delete(wallet),
              child: const Text('删除本地'),
            ),
          ],
        ),
      ],
    ),
  );
}
