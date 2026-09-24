# wallet_cloud_backup 示例

演示 `MnemonicCloudBackup`：用密码加密助记词、备份、列出、恢复。

默认打开"演示模式"，备份存在内存里，不需要 iCloud / Google Drive 配置就能运行。
关闭演示模式前，先按上级目录 README 完成 iCloud Container 或 Google OAuth Client 配置。

点击“生成 TRC20 钱包”或“重新生成”会创建新的 12 词助记词、TRON 收款地址和独立钱包 ID，
助记词会填入输入框。填写备份密码后点击“备份”，当前地址会先与助记词校验，再与助记词一起加密上传；
恢复时会再次校验并显示同一个 TRC20 地址。每次重新生成都会替换输入框中的助记词，
请先安全保存旧钱包的助记词，并确认其备份可恢复。演示模式的备份在 App 退出后会消失。

“查看私钥”会在风险确认后从当前助记词临时派生 TRON 私钥，只在弹窗中显示；不会自动写入
页面状态、剪贴板或云备份。此示例没有设备生物识别/本地密码验证，正式钱包产品应在展示私钥前加入认证，
并防范屏幕录制、截屏和旁观者。

```sh
fvm flutter run
# 设备上的集成测试（真实 Wallet Core + 真实 Argon2id，内存存储）
fvm flutter test integration_test -d <device>
```

Android 需要能取到 Trust Wallet Core SDK，见上级 README 的"wallet_core 配置"。
