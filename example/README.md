# wallet_cloud_backup 示例

示例启动后有两个页面：**本地钱包**按 [多链存储方案](../docs/MULTI_CHAIN_WALLET_STORAGE.md) 的第一版管理钱包；**备份演示**保留原来的 `MnemonicCloudBackup` 演示。

本地钱包页使用 Drift / SQLite 存钱包、账户、网络、地址及完整派生路径，用 `flutter_secure_storage` 存助记词或单独导入的私钥。可创建或导入 HD 钱包、导入 32 字节十六进制私钥、添加观察钱包。HD 钱包默认派生 Ethereum、TRON 和 Bitcoin 首地址；EVM 账户同时关联 Ethereum、Polygon、BNB Smart Chain 网络，并可按地址索引继续派生。页面可验证本地秘密与地址是否一致，或仅删除本机钱包。

在“云备份与恢复”选择云盘并输入备份密码，展开本地 HD 钱包点击“备份到云盘”。Android 可选 Google 云盘或华为云盘；选择华为云时，先检查 HMS Core，必要时由华为官方界面引导安装或更新，再尝试静默授权，必要时显示华为官方登录界面。示例会设置或验证本地 Web3 钱包密码（仅把带盐 PBKDF2 校验值放在设备安全存储中），云备份密码单独用于本机加密。上传前检查同 ID 的云备份：若内容相同则跳过；云端读回确认后才显示“已备份”和最近确认时间。上传超时后先查云端是否提交成功，失败时保留原有状态。

追加备份默认验证已有云备份密码。忘记旧密码时，可勾选“为新备份设置新密码”；旧备份仍需原密码，同 ID 已有备份不会被覆盖。恢复需要对应备份密码，解密后校验地址，再设置或验证本地钱包密码。删除需确认并验证本地钱包密码。华为云列表按当前 HUAWEI ID 隔离；切换账号后点击“刷新账号”重新查询，旧账号的备份不能用新账号授权删除。备份使用当前插件的 v1 格式，**不会备份**导入的私钥、观察钱包、自定义地址索引和账户配置；恢复到全新设备时只重建三个默认地址。本版只支持空 BIP39 passphrase。云备份密码每次输入，不保存在本机；私钥钱包的云备份和完整配置恢复仍需文档中的 v2 格式。

本地数据库记录地址和名称，未做整库加密；助记词和私钥不写入 SQLite。本地 Web3 密码是操作校验门槛，当前示例的设备安全存储仍负责保护密钥，并未以这个密码重新加密密钥。Android 示例禁用系统 Auto Backup；iOS 将数据库置于 `Application Support/wallet_local` 并标记为不进入普通设备备份。本示例没有 App 解锁、交易确认或生物识别，不能直接作为生产钱包使用。

华为云盘需要在 AppGallery Connect 为**实际包名与签名证书**启用 Account Kit 和 Drive Kit，将自己的 `agconnect-services.json` 放入 `android/app/`。仓库不包含这个账号专属配置。示例已加华为 Maven 仓库、AGConnect Gradle 插件及 `huawei_account`、`huawei_hmsavailability`、`huawei_drive` 依赖；详情见上级 README 的 [Huawei Drive 配置](../README.md#androidhuawei-drive可选)。本机没有华为设备和 AppGallery 配置，登录、上传与恢复仍需在真机上验证。

## 备份演示页

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
