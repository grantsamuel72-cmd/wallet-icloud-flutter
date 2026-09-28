import 'package:flutter/foundation.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/data/wallet_repository.dart';
import 'package:wallet_cloud_backup_example/domain/wallet_models.dart';
import 'package:wallet_core/wallet_core.dart';

class WalletManagerViewModel extends ChangeNotifier {
  WalletManagerViewModel(this.repository);

  final WalletRepository repository;

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

  Future<void> backup(String walletId, String password) async {
    await _run<BackupHdResult>(
      '备份',
      () async {
        final ready = await repository.backups.cloud.connect(interactive: true);
        if (!ready) throw StateError('未登录云盘或取消了授权。');
        final result = await repository.backupHd(walletId, password);
        wallets = await repository.listWallets();
        return result;
      },
      successMessage: (result) => result == BackupHdResult.alreadyBackedUp
          ? '云端已有相同钱包备份，已跳过重复上传。'
          : '备份到云盘成功。',
    );
  }

  Future<void> connectCloud() => _run('连接云盘', () async {
    final ready = await repository.backups.cloud.connect(interactive: true);
    if (!ready) throw StateError('未登录云盘或取消了授权。');
  });

  Future<void> loadCloud() => _run('列出云备份', () async {
    cloudWallets = await repository.listCloudWallets();
  });

  Future<void> restore(RestorableWallet entry, String password) =>
      _run('恢复', () async {
        await repository.restoreHd(entry, password);
        wallets = await repository.listWallets();
      });

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
