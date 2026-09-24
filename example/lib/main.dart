import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/memory_backup_store.dart';
import 'package:wallet_cloud_backup_example/wallet_generation_controls.dart';
import 'package:wallet_cloud_backup_example/wallet_generation_service.dart';
import 'package:wallet_core/wallet_core.dart';

/// Must match `com.apple.developer.ubiquity-container-identifiers` in
/// ios/Runner/Runner.entitlements; replace both with your own container.
const _iCloudContainerId = 'iCloud.com.uux.dev';

/// Container-relative folder. Without a `Documents/` prefix the Files app does
/// not show it, so the user cannot delete their only backup by hand.
const _iCloudFolder = 'WalletBackups';

/// Public BIP39 test vector. Never put funds on it.
const _demoMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() =>
    runApp(const MaterialApp(title: '钱包云备份示例', home: BackupDemoPage()));

MnemonicCloudBackup _defaultBackups(WalletCloudBackup cloud) =>
    MnemonicCloudBackup(cloud);

class BackupDemoPage extends StatefulWidget {
  const BackupDemoPage({
    super.key,
    this.createBackups = _defaultBackups,
    this.walletGenerator,
  });

  /// Builds the mnemonic backup service on top of a storage backend.
  /// Tests pass one with a fake Wallet Core.
  final MnemonicCloudBackup Function(WalletCloudBackup cloud) createBackups;

  /// Generator used by both create and regenerate actions.
  final WalletGenerationService? walletGenerator;

  @override
  State<BackupDemoPage> createState() => _BackupDemoPageState();
}

class _BackupDemoPageState extends State<BackupDemoPage> {
  final _walletId = TextEditingController(text: 'demo-wallet');
  final _mnemonic = TextEditingController(text: _demoMnemonic);
  final _password = TextEditingController();
  final _label = TextEditingController(text: '主钱包');
  late final WalletGenerationService _walletGenerator =
      widget.walletGenerator ?? WalletGenerationService();

  bool _demoMode = true;
  bool _busy = false;
  String _status = '演示模式：备份只保存在内存里。';
  List<RestorableWallet> _wallets = const <RestorableWallet>[];
  List<CloudBackupFile> _containerFiles = const <CloudBackupFile>[];
  bool _diagnosed = false;
  bool _providerReady = false;
  String? _currentTronAddress;
  late MnemonicCloudBackup _backups = _createBackups();

  MnemonicCloudBackup _createBackups() => widget.createBackups(
    _demoMode
        ? WalletCloudBackup.withStore(MemoryBackupStore())
        : WalletCloudBackup(
            iCloud: const ICloudOptions(
              containerId: _iCloudContainerId,
              folder: _iCloudFolder,
            ),
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
      if (mounted) setState(() => _status = result);
    } on WrongBackupPasswordException {
      if (mounted) setState(() => _status = '密码不对，请重试。');
    } on WeakBackupPasswordException catch (error) {
      if (mounted) setState(() => _status = '密码至少 ${error.minLength} 个字符。');
    } on WalletCloudBackupException catch (error) {
      if (mounted) setState(() => _status = '$action失败：${error.message}');
    } on WalletCoreException catch (error) {
      if (mounted) {
        setState(() => _status = '$action失败：Wallet Core 不可用（${error.code}）。');
      }
    } on MissingPluginException {
      if (mounted) setState(() => _status = '$action失败：Wallet Core 插件未注册。');
    } on UnsupportedError {
      if (mounted) setState(() => _status = '$action失败：当前平台不支持 Wallet Core。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run('连接', () async {
    final ready = await _backups.cloud.connect(interactive: true);
    return ready ? '已连接 ${_backups.cloud.provider.name}。' : '未连接：未登录或已取消。';
  });

  Future<void> _generateWallet() => _run('生成', () async {
    final generated = await _walletGenerator.generate();
    _walletId.text = generated.walletId;
    _mnemonic.text = generated.mnemonic;
    _currentTronAddress = generated.tronAddress;
    return '已生成 TRC20 钱包，请妥善保管助记词。';
  });

  Future<void> _viewPrivateKey() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('查看 TRON 私钥？'),
        content: const Text('私钥可完全控制此地址的资产。请确认周围无人，不要截图、分享或输入到陌生网站。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('继续查看'),
          ),
        ],
      ),
    );
    if (!mounted || approved != true) return;

    await _run('查看私钥', () async {
      final export = await _walletGenerator.exportTronPrivateKey(
        _mnemonic.text,
      );
      if (_currentTronAddress != null &&
          _currentTronAddress != export.tronAddress) {
        throw const BackupIntegrityException('当前 TRON 地址与助记词不匹配。');
      }
      _currentTronAddress = export.tronAddress;
      if (!mounted) return '私钥未显示。';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('TRON 私钥'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('地址：${export.tronAddress}'),
                const SizedBox(height: 12),
                SelectableText(
                  export.privateKeyHex,
                  key: const Key('tron-private-key'),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
      return '私钥已隐藏。';
    });
  }

  Future<void> _backup() => _run('备份', () async {
    final mnemonic = _mnemonic.text;
    final tronAddress = await _backups.tronAddressForMnemonic(mnemonic);
    if (_currentTronAddress != null && _currentTronAddress != tronAddress) {
      throw const BackupIntegrityException('当前 TRC20 地址与助记词不匹配。');
    }
    await _backups.backupMnemonic(
      walletId: _walletId.text,
      mnemonic: mnemonic,
      password: _password.text,
      label: _label.text,
      tronAddress: tronAddress,
    );
    _currentTronAddress = tronAddress;
    _wallets = await _backups.listRestorable();
    return '已加密并上传当前 TRC20 地址，已回读校验。';
  });

  Future<void> _list() => _run('列出', () async {
    _wallets = await _backups.listRestorable();
    return '找到 ${_wallets.length} 个备份。';
  });

  /// Reads the backend directly, so the listing is what is really in the
  /// container rather than what the package recognises as a wallet backup.
  Future<void> _diagnose() => _run('诊断', () async {
    final store = _backups.cloud.store;
    _providerReady = await store.connect();
    _containerFiles = await store.list();
    _diagnosed = true;
    return _containerFiles.isEmpty
        ? '容器里还没有文件。'
        : '容器里有 ${_containerFiles.length} 个文件。';
  });

  Future<void> _restore(String walletId) => _run('恢复', () async {
    final wallet = await _backups.restoreWallet(
      walletId,
      password: _password.text,
    );
    try {
      final address = await wallet.getAddress(CoinType.tron);
      _walletId.text = walletId;
      _mnemonic.text = await wallet.getMnemonic();
      _currentTronAddress = address;
      return '恢复成功，TRC20 地址：$address';
    } finally {
      await wallet.dispose();
    }
  });

  static String _describeFile(CloudBackupFile file) {
    final size = file.sizeInBytes;
    final changedAt = file.modifiedAt ?? file.createdAt;
    return <String>[
      size == null ? '大小未知' : '$size 字节',
      changedAt == null ? '时间未知' : '${changedAt.toLocal()}',
      if (file.hasUnresolvedConflicts) '有未解决的冲突',
    ].join(' · ');
  }

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
                _containerFiles = const <CloudBackupFile>[];
                _diagnosed = false;
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
              onChanged: (_) => setState(() => _currentTronAddress = null),
              maxLines: 2,
              // A real phrase typed here would otherwise reach the keyboard's
              // learned vocabulary and its suggestion bar. All three default
              // to on, so a wallet app has to turn them off explicitly.
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              decoration: const InputDecoration(labelText: '助记词（示例为公开测试向量）'),
            ),
            const SizedBox(height: 8),
            WalletGenerationControls(
              onGenerate: _generateWallet,
              onRegenerate: _generateWallet,
              onViewPrivateKey: _viewPrivateKey,
              tronAddress: _currentTronAddress,
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
                OutlinedButton(onPressed: _diagnose, child: const Text('诊断')),
              ],
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            Text(_status),
            if (_diagnosed) ...<Widget>[
              const Divider(height: 32),
              Text('存储位置', style: Theme.of(context).textTheme.titleSmall),
              Text(
                _demoMode
                    ? '内存存储，什么都没有写到云端。'
                    : '后端：${_backups.cloud.provider.name}\n'
                          '容器：$_iCloudContainerId\n'
                          '目录：$_iCloudFolder/（Files App 和 iCloud.com 都看不到，这是有意的）',
              ),
              Text(_providerReady ? '连接状态：可用' : '连接状态：不可用（未登录 iCloud，或云盘已关闭）'),
              const SizedBox(height: 8),
              for (final file in _containerFiles)
                ListTile(
                  dense: true,
                  title: Text(file.name),
                  subtitle: Text(_describeFile(file)),
                ),
              const Divider(height: 32),
            ],
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
