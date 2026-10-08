import 'package:flutter/foundation.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/data/huawei_cloud_session.dart';
import 'package:wallet_cloud_backup_example/data/local_wallet_password.dart';
import 'package:wallet_cloud_backup_example/data/wallet_repository.dart';
import 'package:wallet_cloud_backup_example/domain/wallet_models.dart';
import 'package:wallet_core/wallet_core.dart';

class WalletManagerViewModel extends ChangeNotifier {
  WalletManagerViewModel(
    this.repository, {
    this.huaweiSession,
    this.huaweiBackups,
    this.localPassword,
  }) : _defaultBackups = repository.backups,
       selectedProvider = repository.backups.cloud.provider;

  final WalletRepository repository;
  final HuaweiCloudSession? huaweiSession;
  final MnemonicCloudBackup? huaweiBackups;
  final LocalWalletPassword? localPassword;
  final MnemonicCloudBackup _defaultBackups;
  CloudBackupProvider selectedProvider;
  String? _huaweiAccountId;

  String? get huaweiAccountId => _huaweiAccountId;

  Future<bool> localPasswordConfigured() async =>
      await localPassword?.isConfigured() ?? false;

  Future<void> _checkLocalPassword(
    String password, {
    bool allowSetup = false,
  }) async {
    final gate = localPassword;
    if (gate == null) return;
    if (await gate.isConfigured()) {
      if (!await gate.verify(password)) throw StateError('Web3 钱包密码错误。');
    } else if (allowSetup) {
      await gate.set(password);
    } else {
      throw StateError('请先设置 Web3 钱包密码。');
    }
  }

  List<StoredWallet> wallets = const <StoredWallet>[];
  List<RestorableWallet> cloudWallets = const <RestorableWallet>[];
  bool busy = false;
  String status = '本地钱包保存在设备上；云备份只保存 HD 助记词。';

  Future<void> load() => _run('加载', () async {
    wallets = await repository.listWallets();
  });

  Future<CreatedWallet?> createHd(String name, {String? mnemonic}) => _run(
    '创建钱包',
    () async {
      final created = await repository.createHd(name: name, mnemonic: mnemonic);
      wallets = await repository.listWallets();
      return created;
    },
  );

  Future<void> importPrivateKey(String name, String key) =>
      _run('导入私钥', () async {
        await repository.importPrivateKey(name: name, keyHex: key);
        wallets = await repository.listWallets();
      });

  Future<void> addWatchOnly(String name, WalletChain chain, String address) =>
      _run('添加观察钱包', () async {
        await repository.addWatchOnly(
          name: name,
          chain: chain,
          address: address,
        );
        wallets = await repository.listWallets();
      });

  Future<void> addAddress(String walletId, WalletChain chain, int index) =>
      _run('添加地址', () async {
        await repository.addHdAddress(walletId, chain, index);
        wallets = await repository.listWallets();
      });

  Future<void> verify(String walletId) => _run('验证钱包', () async {
    await repository.verifyLocalWallet(walletId);
  });

  Future<void> selectCloud(CloudBackupProvider provider) =>
      _run('连接云盘', () async {
        if (provider == CloudBackupProvider.huaweiDrive) {
          final session = huaweiSession;
          final service = huaweiBackups;
          if (session == null || service == null) {
            throw UnsupportedError('此示例未配置华为云盘。');
          }
          final store = service.cloud.store as HuaweiDriveBackupStore;
          final previousId = _huaweiAccountId;
          store.bindAccount(null);
          await store.disconnect();
          bool ready;
          try {
            ready = await service.cloud.connect(interactive: true);
          } catch (_) {
            store.bindAccount(previousId);
            rethrow;
          }
          if (!ready) {
            store.bindAccount(previousId);
            throw StateError('已取消华为账号授权。');
          }
          final id = session.accountId;
          if (id == null) throw StateError('无法确认当前华为账号。');
          store.bindAccount(id);
          _huaweiAccountId = id;
          repository.useCloud(service, 'huawei:$id');
        } else {
          _huaweiAccountId = null;
          repository.useCloud(_defaultBackups, 'default');
        }
        selectedProvider = provider;
        cloudWallets = const <RestorableWallet>[];
        wallets = await repository.listWallets();
      });

  Future<void> _readyCloud() async {
    bool ready;
    try {
      ready = await repository.backups.cloud.connect(interactive: true);
    } on CloudAuthenticationException {
      if (selectedProvider == CloudBackupProvider.huaweiDrive &&
          huaweiSession?.accountId != null &&
          huaweiSession?.accountId != _huaweiAccountId) {
        cloudWallets = const <RestorableWallet>[];
        _huaweiAccountId = null;
        repository.useCloud(repository.backups, 'huawei:unselected');
        wallets = await repository.listWallets();
      }
      rethrow;
    }
    if (!ready) throw StateError('未登录云盘或取消了授权。');
    if (selectedProvider == CloudBackupProvider.huaweiDrive &&
        huaweiSession?.accountId != _huaweiAccountId) {
      cloudWallets = const <RestorableWallet>[];
      throw StateError('华为账号已切换，请重新选择华为云并查询当前账号备份。');
    }
  }

  Future<void> backup(
    String walletId,
    String password, {
    bool useNewPassword = false,
    String localWalletPassword = '',
  }) async {
    await _run<BackupHdResult>(
      '备份',
      () async {
        await _checkLocalPassword(localWalletPassword, allowSetup: true);
        await _readyCloud();
        final result = await repository.backupHd(
          walletId,
          password,
          useNewPassword: useNewPassword,
        );
        wallets = await repository.listWallets();
        return result;
      },
      successMessage: (result) => result == BackupHdResult.alreadyBackedUp
          ? '云端已有相同钱包备份，已跳过重复上传。'
          : '已备份。',
    );
  }

  Future<void> connectCloud() => _run('连接云盘', () async {
    await _readyCloud();
  });

  Future<void> loadCloud() => _run('列出云备份', () async {
    await _readyCloud();
    cloudWallets = await repository.listCloudWallets();
  });

  Future<void> restore(
    RestorableWallet entry,
    String password, {
    String localWalletPassword = '',
  }) => _run('恢复', () async {
    await _readyCloud();
    if (!cloudWallets.contains(entry)) throw StateError('请重新查询当前账号的备份。');
    await repository.backups.restoreMnemonic(
      entry.walletId,
      password: password,
    );
    await _checkLocalPassword(localWalletPassword, allowSetup: true);
    await repository.restoreHd(entry, password);
    wallets = await repository.listWallets();
  });

  Future<void> deleteCloud(
    RestorableWallet entry, {
    String localWalletPassword = '',
  }) => _run('删除云备份', () async {
    await _checkLocalPassword(localWalletPassword);
    await _readyCloud();
    if (!cloudWallets.contains(entry)) throw StateError('请重新查询当前账号的备份。');
    await repository.deleteCloudBackup(entry);
    cloudWallets = List<RestorableWallet>.unmodifiable(
      cloudWallets.where((item) => item.walletId != entry.walletId),
    );
    wallets = await repository.listWallets();
  }, successMessage: (_) => '备份已删除。');

  Future<void> deleteLocal(String walletId) => _run('删除本地钱包', () async {
    await repository.deleteLocal(walletId);
    wallets = await repository.listWallets();
  });

  Future<T?> _run<T>(
    String action,
    Future<T> Function() body, {
    String Function(T result)? successMessage,
  }) async {
    if (busy) return null;
    busy = true;
    status = '$action…';
    notifyListeners();
    try {
      final result = await body();
      status = successMessage?.call(result) ?? '$action成功。';
      return result;
    } on WrongBackupPasswordException {
      status = '备份密码错误。';
    } on WalletCloudBackupException catch (error) {
      status = '$action失败：${error.message}';
    } on WalletCoreException catch (error) {
      status = '$action失败：Wallet Core ${error.code}。';
    } on FormatException catch (error) {
      status = '$action失败：${error.message}';
    } on StateError catch (error) {
      status = '$action失败：${error.message}';
    } on RangeError {
      status = '$action失败：地址索引超出范围。';
    } on ArgumentError {
      status = '$action失败：输入参数无效。';
    } on UnsupportedError {
      status = '$action失败：当前平台不支持此操作。';
    } on Exception {
      status = '$action失败，请检查平台配置后重试。';
    } finally {
      busy = false;
      notifyListeners();
    }
    return null;
  }
}
