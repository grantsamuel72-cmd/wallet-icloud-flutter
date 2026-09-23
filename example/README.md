# wallet_cloud_backup 示例

演示 `MnemonicCloudBackup`：用密码加密助记词、备份、列出、恢复。

默认打开"演示模式"，备份存在内存里，不需要 iCloud / Google Drive 配置就能运行。
关闭演示模式前，先按上级目录 README 完成 iCloud Container 或 Google OAuth Client 配置。

```sh
fvm flutter run
# 设备上的集成测试（真实 Wallet Core + 真实 Argon2id，内存存储）
fvm flutter test integration_test -d <device>
```

Android 需要能取到 Trust Wallet Core SDK，见上级 README 的"wallet_core 配置"。
