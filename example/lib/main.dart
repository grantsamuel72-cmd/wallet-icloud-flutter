import 'package:flutter/material.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/memory_backup_store.dart';
import 'package:wallet_core/wallet_core.dart';

/// Must match `com.apple.developer.ubiquity-container-identifiers` in
/// ios/Runner/Runner.entitlements; replace both with your own container.
const _iCloudContainerId = 'iCloud.com.uux.dev';

/// Public BIP39 test vector. Never put funds on it.
const _demoMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() =>
    runApp(const MaterialApp(title: '钱包云备份示例', home: BackupDemoPage()));

MnemonicCloudBackup _defaultBackups(WalletCloudBackup cloud) =>
    MnemonicCloudBackup(cloud);

class BackupDemoPage extends StatefulWidget {
  const BackupDemoPage({super.key, this.createBackups = _defaultBackups});

  /// Builds the mnemonic backup service on top of a storage backend.
  /// Tests pass one with a fake Wallet Core.
  final MnemonicCloudBackup Function(WalletCloudBackup cloud) createBackups;

  @override
  State<BackupDemoPage> createState() => _BackupDemoPageState();
}

class _BackupDemoPageState extends State<BackupDemoPage> {
  final _walletId = TextEditingController(text: 'demo-wallet');
  final _mnemonic = TextEditingController(text: _demoMnemonic);
  final _password = TextEditingController();
  final _label = TextEditingController(text: '主钱包');

  bool _demoMode = true;
  bool _busy = false;
  String _status = '演示模式：备份只保存在内存里。';
  List<RestorableWallet> _wallets = const <RestorableWallet>[];
  late MnemonicCloudBackup _backups = _createBackups();

  MnemonicCloudBackup _createBackups() => widget.createBackups(
    _demoMode
        ? WalletCloudBackup.withStore(MemoryBackupStore())
        : WalletCloudBackup(
            iCloud: const ICloudOptions(containerId: _iCloudContainerId),
          ),
  );

  @override
  void dispose() {
    _walletId.dispose();
    _mnemonic.dispose();
    _password.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _run(String action, Future<String> Function() task) async {
    setState(() {
      _busy = true;
      _status = '$action…';
    });
    try {
      final result = await task();
      setState(() => _status = result);
    } on WrongBackupPasswordException {
      setState(() => _status = '密码不对，请重试。');
    } on WeakBackupPasswordException catch (error) {
      setState(() => _status = '密码至少 ${error.minLength} 个字符。');
    } on WalletCloudBackupException catch (error) {
      setState(() => _status = '$action失败：${error.message}');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run('连接', () async {
    final ready = await _backups.cloud.connect(interactive: true);
    return ready ? '已连接 ${_backups.cloud.provider.name}。' : '未连接：未登录或已取消。';
  });

  Future<void> _backup() => _run('备份', () async {
    await _backups.backupMnemonic(
      walletId: _walletId.text,
      mnemonic: _mnemonic.text,
      password: _password.text,
      label: _label.text,
    );
    _wallets = await _backups.listRestorable();
    return '已加密并上传，已回读校验。';
  });

  Future<void> _list() => _run('列出', () async {
    _wallets = await _backups.listRestorable();
    return '找到 ${_wallets.length} 个备份。';
  });

  Future<void> _restore(String walletId) => _run('恢复', () async {
    final wallet = await _backups.restoreWallet(
      walletId,
      password: _password.text,
    );
    try {
      final address = await wallet.getAddress(CoinType.ethereum);
      return '恢复成功，ETH 地址：$address';
    } finally {
      await wallet.dispose();
    }
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('钱包云备份示例')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SwitchListTile(
              title: const Text('演示模式（内存存储）'),
              subtitle: const Text('关闭后使用 iCloud / Google Drive，需要先完成平台配置'),
              value: _demoMode,
              onChanged: (value) => setState(() {
                _demoMode = value;
                _wallets = const <RestorableWallet>[];
                _backups = _createBackups();
              }),
            ),
            TextField(
              controller: _walletId,
              decoration: const InputDecoration(labelText: '钱包 ID'),
            ),
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: '显示名称（明文保存）'),
            ),
            TextField(
              controller: _mnemonic,
              maxLines: 2,
              // A real phrase typed here would otherwise reach the keyboard's
              // learned vocabulary and its suggestion bar. All three default
              // to on, so a wallet app has to turn them off explicitly.
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              decoration: const InputDecoration(labelText: '助记词（示例为公开测试向量）'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: '备份密码（至少 8 个字符）'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: <Widget>[
                if (!_demoMode)
                  FilledButton(onPressed: _connect, child: const Text('连接云盘')),
                FilledButton(onPressed: _backup, child: const Text('备份')),
                OutlinedButton(onPressed: _list, child: const Text('列出备份')),
              ],
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            Text(_status),
            for (final wallet in _wallets)
              ListTile(
                title: Text(wallet.label ?? wallet.walletId),
                subtitle: Text(
                  wallet.error?.message ??
                      '${wallet.walletId} · ${wallet.createdAt}',
                ),
                trailing: wallet.isRestorable
                    ? TextButton(
                        onPressed: () => _restore(wallet.walletId),
                        child: const Text('恢复'),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
