# 多链、多钱包存储方案

状态：设计稿。适用范围：本仓库支持的 iOS、Android Flutter 钱包；`wallet_core` 负责派生和签名，`wallet_cloud_backup` 负责加密云备份的上传与恢复。

`example/` 已实现下文的第一版本地钱包与现有 HD 助记词云备份流程；统一的 `portable_wallet.v2` 仍是待实现的格式，详见 [example 使用说明](../example/README.md)。

## 1. 决策与边界

| 数据 | 主存储 | 云端 | 说明 |
| --- | --- | --- | --- |
| 钱包名称、账户、链、地址、完整派生路径 | Drift / SQLite | 随加密钱包清单备份 | 可查询、可迁移；地址不是秘密，但会暴露用户关联关系 |
| HD 钱包助记词 | `flutter_secure_storage` | 用户设置独立备份密码后加密上传 | 每个 HD 钱包只存一份，不持久化派生私钥 |
| 单独导入的私钥 | `flutter_secure_storage` | 需扩展加密备份格式后才能上传 | 每把导入的私钥有独立 `secretRef` |
| BIP39 passphrase（“第 25 个词”） | 默认不保存，使用时由用户输入 | 默认不上传 | 丢失后无法恢复该隐藏钱包，即使助记词仍在 |
| 余额、价格、交易历史 | SQLite 缓存，可删除重建 | 不备份 | 链上或索引服务才是数据来源 |
| 备份密码、App 解锁 PIN、云访问令牌 | 不存入 Drift | 不上传备份密码 | PIN 不等于备份密码；访问令牌由相应平台插件管理 |

本地数据库**不保存明文助记词、私钥、passphrase 或备份密码**。普通 SQLite 数据库和它的 WAL、设备备份都不能作为秘密保险箱。此方案中的地址与标签在本地数据库里可读；若产品要求连这类关联信息也加密，可为 Drift 接入加密 SQLite，并把数据库密钥交由系统安全存储保护。不要把数据库密钥写入同一数据库。iOS 使用 Keychain 的 `unlocked_this_device` 访问级别；Android 使用 `flutter_secure_storage` 的加密存储，并在宿主 App 中排除相关 SharedPreferences 的系统 Auto Backup。`ThisDeviceOnly` 数据不会迁移到新设备，所以恢复必须依靠用户持有的助记词或独立的加密云备份。[Keychain 可访问性](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly) · [Flutter 安全存储](https://pub.dev/packages/flutter_secure_storage)

## 2. 标识与数据模型

- `walletId`：随机 UUID，与地址、助记词、设备 ID 无关。作为本地和云端的稳定关联键；云端文件名会泄露此 ID，不能放个人信息。
- `wallet.kind`：`hd`、`imported_key`、`watch_only`。硬件钱包暂不纳入本方案；后续增加时不能假装其私钥可导出。
- `account`：一个钱包下某个链族和派生账户。保存 `coinType`、地址格式及钱包派生规则版本；具体地址行保存完整 BIP32 路径，不靠“默认路径”在恢复时猜测。
- `address`：账户下的一条地址记录。UTXO 链区分 external/change 和地址索引；EVM 不按每条网络重复派生同一个地址，而是让账户关联多个网络。
- `networkId`：带命名空间的稳定链标识，例如 `eip155:1`、`eip155:137`；BTC 主网、测试网也必须分开。`coinType` 是 Wallet Core 参数，不代替网络 ID。
- `secretRef`：安全存储的随机、不含秘密的键名，例如 `wallet/<walletId>/mnemonic`。Drift 只保存引用。

建议的 SQLite v1 表结构如下。地址规范化必须按链实现：EVM 可小写用于比较，Base58 地址不能一概转小写；展示时保留原格式。

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE wallets (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('hd', 'imported_key', 'watch_only')),
  name TEXT NOT NULL,
  secret_ref TEXT UNIQUE,
  state TEXT NOT NULL DEFAULT 'ready'
    CHECK (state IN ('ready', 'deleting', 'needs_restore')),
  requires_bip39_passphrase INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  CHECK ((kind = 'watch_only' AND secret_ref IS NULL)
      OR (kind <> 'watch_only' AND secret_ref IS NOT NULL))
);

CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  wallet_id TEXT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
  chain_family TEXT NOT NULL,
  coin_type INTEGER NOT NULL,
  account_index INTEGER NOT NULL DEFAULT 0,
  address_format TEXT NOT NULL,
  derivation_profile TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE INDEX accounts_by_wallet ON accounts(wallet_id);

CREATE TABLE addresses (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  derivation_path TEXT NOT NULL DEFAULT '',
  change_index INTEGER,
  address_index INTEGER,
  address TEXT NOT NULL,
  address_normalized TEXT NOT NULL,
  is_primary INTEGER NOT NULL DEFAULT 0,
  UNIQUE(account_id, derivation_path),
  UNIQUE(account_id, address_normalized)
);

CREATE TABLE networks (
  id TEXT PRIMARY KEY,
  chain_family TEXT NOT NULL,
  display_name TEXT NOT NULL
);
CREATE TABLE account_networks (
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  network_id TEXT NOT NULL REFERENCES networks(id),
  enabled INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (account_id, network_id)
);

CREATE TABLE backup_status (
  wallet_id TEXT PRIMARY KEY REFERENCES wallets(id) ON DELETE CASCADE,
  state TEXT NOT NULL CHECK (state IN ('none', 'dirty', 'verified', 'failed')),
  remote_checksum TEXT,
  last_verified_at TEXT
);
```

`derivation_path = ''` 只用于导入私钥或观察钱包。HD 地址必须有完整路径，例如 `m/44'/60'/0'/0/0`；UTXO 地址同时记录 `change_index`、`address_index`。添加路径或地址时，用 `wallet_core` 派生一次并保存结果；恢复时按保存的路径重新派生，逐条比对地址。不同链若共用公钥，也按链的编码规则分别验证。

Drift 负责 schema 版本、迁移、事务和响应式查询。数据库迁移不能修改已有钱包的派生路径或静默重算地址；新派生规则须用新的 `derivation_profile`。默认将本地数据库排除系统的普通设备备份，换机通过加密钱包备份重建，避免系统备份单独带走地址关系或产生缺少安全存储条目的“半恢复”。[Drift 官方文档](https://drift.simonbinder.eu/)

## 3. 本地秘密与使用流程

1. 创建或导入 HD 钱包：`wallet_core` 校验助记词；为钱包生成 UUID；先写安全存储，再在 Drift 事务中写钱包、账户和首个地址。若事务失败，删除刚写入的秘密。
2. 导入私钥：先验证密钥长度、曲线和目标链；安全存储保存原始导入密钥；Drift 保存其 `secretRef`、账户及可验证的地址。**不要**把这把密钥伪装成 HD 助记词。
3. 观察钱包：仅写地址和网络，不创建 `secretRef`，签名入口明确禁用。
4. 签名：需要时读秘密并创建短生命周期 `HDWallet`，按选定路径签名，`try/finally` 调用 `dispose()`；只在用户确认交易后读取秘密。不要长期缓存 `HDWallet`、助记词或派生私钥，也不要将它们写入日志、崩溃报告、剪贴板或截图。
5. 启动时做一致性检查：`secretRef` 丢失的记录显示为“需恢复”，不能当作可签名钱包；无数据库引用的安全存储条目延迟清理，先排除进行中的导入/恢复。

Drift 与平台安全存储没有跨存储事务，所以创建和删除使用可重试状态机。删除钱包时先标记 `deleting` 并停止签名，再删本地秘密与数据库记录；云备份是否删除必须作为独立的用户操作，不能由本地删除隐式触发。

`flutter_secure_storage` 能保护静态存储，不意味着助记词永远不进入应用进程。Wallet Core 的 `getMnemonic` 等导出接口会把秘密交给 Dart；只在确有需要时调用，并限制明文生命周期。Android Keystore 保护用于加密的密钥材料，但并不代替 App 的交易确认和解锁策略。[Android Keystore](https://developer.android.com/privacy-and-security/keystore) · [Wallet Core API](https://github.com/grantsamuel72-cmd/wallet-core-flutter)

## 4. 云备份：当前可用能力与目标格式

### 当前仓库可直接使用

`MnemonicCloudBackup.backupMnemonic/backupWallet` 已能用 Argon2id + AES-256-GCM 加密 HD 助记词，上传后读回校验；`restoreMnemonic/restoreWallet` 可恢复，`listRestorable` 可列出备份。每个 `walletId` 对应一个云文件。BIP39 passphrase **没有**包含在当前备份中，钱包名称 `label` 在云文件里是明文；当前格式也没有保存所有链的账户、地址和自定义派生路径。因此仅恢复助记词不足以完整重建复杂钱包。[现有备份说明](../README.md#助记词加密备份推荐)

`WalletCloudBackup.backup(WalletBackup)` 可上传任意已经加密的 JSON；它验证外层 checksum，但 **checksum 不提供保密性，也不能替代认证加密**。导入私钥或完整配置不能直接作为 `encryptedKeystore` 的明文传入。[底层 API](../README.md#底层-api自己加密的-keystore)

### 要实现的统一钱包备份 v2

在本插件增加一个高层 `PortableWalletBackup`（名称可在实现时确定），沿用当前安全参数，并让一个钱包的秘密和恢复清单进入**同一份认证加密密文**。每个钱包仍只有一个云文件，不把秘密和派生配置拆成可能不同步的两个文件。

```json
{
  "formatVersion": 1,
  "walletId": "随机 UUID",
  "encryptedKeystore": {
    "scheme": "wallet_cloud_backup.portable_wallet.v2",
    "kind": "hd",
    "keyDerivation": {"algorithm": "argon2id", "memoryKiB": 65536, "iterations": 3, "parallelism": 4, "salt": "base64"},
    "algorithm": "AES-256-GCM",
    "nonce": "base64",
    "cipherText": "base64",
    "mac": "base64"
  },
  "createdAt": "UTC ISO-8601",
  "checksum": "SHA-256"
}
```

上例是**目标格式，不是现有 API 已支持的格式**。密文内的版本化负载包含：`kind`、助记词或导入私钥、钱包名称、账户列表、每个账户的 `coinType`/完整派生路径/地址格式/地址校验值、启用的网络。观察钱包只有配置，没有秘密。余额、价格、交易历史不包含在备份中。

- 备份密码由用户设置，与 App 解锁 PIN 分开；应用不持久化备份密码。产品层要求长口令和强度提示，不能仅满足插件当前的 8 字符最低门槛。密码丢失时云备份无法解密。
- 每个文件生成独立随机 salt 和 nonce；Argon2id 使用 64 MiB、3 轮、4 并行；由主密钥经 HKDF 分出 AES-256-GCM 密钥。把 `walletId`、`kind`、版本、创建时间和全部公开头字段作为 AAD，防止跨钱包替换或头字段篡改。读取前限制文件大小及 KDF 成本，再解密。
- `requires_bip39_passphrase = 1` 时，默认仍不上传 passphrase；恢复页必须要求用户输入并用保存的地址校验值验证。若将来支持“连同 passphrase 一起备份”，必须让用户明确选择，因为这会使单个备份密码同时保护两个秘密。
- 写入完成后重新下载、解密并比对内容摘要及派生地址，成功后才将 `backup_status.state` 标记为 `verified`。本地有新地址或新账户时标记 `dirty`，在用户再次输入备份密码后更新云文件。
- v2 解码器要继续读取现有 `wallet_cloud_backup.mnemonic.v1`；恢复 v1 时提示“只能恢复助记词，需重新扫描或手动重建自定义路径”，用户确认后才能写回 v2。

## 5. 恢复、冲突与跨平台

恢复顺序：连接云盘 → 列出并下载候选文件 → 校验大小、版本和 KDF 参数 → 用户输入备份密码 → AEAD 解密 → `wallet_core` 校验助记词/私钥和地址 → 写本地安全存储 → Drift 事务写账户与地址 → 读回并核对 → 标记可用。整个过程失败时不得留下“可签名但缺秘密”或“秘密与地址不符”的钱包。

当前 iOS 写入 iCloud Drive 的应用容器，Android 写入 Google Drive 的 `appDataFolder`。**两种云盘不是同一个账户空间**：iPhone 到 Android 的自动云恢复不可用；跨系统迁移需要另行设计用户主动导出的加密文件，或共同的后端。[平台说明](../README.md#平台配置)

云备份是灾难恢复，不是实时多设备数据库同步。iCloud 可列出冲突版本并要求用户确认；Android 当前插件只暴露一个当前版本，没有条件写入接口。两台设备同时修改同一钱包时，不能声称自动合并；UI 应显示最近备份时间，恢复最新版本后再修改，并在冲突时要求人工确认。不要用设备时间戳直接决定哪份秘密正确。

## 6. 落地顺序与验收

1. **本地最小版**：App 引入 `drift`、`flutter_secure_storage`、`wallet_core`；建上述表和 `SecretStore` 抽象，实现 HD、导入私钥、观察钱包的创建、签名和删除。验证重启后地址一致、秘密不在数据库/WAL/日志中。
2. **现有云备份接入**：HD 钱包使用 `MnemonicCloudBackup`；UI 明确显示“只备份助记词”、passphrase 缺失风险和自定义路径恢复限制。测试错误密码、损坏文件、离线、授权取消及 iCloud 初次同步延迟。
3. **统一 v2 备份**：扩展插件的高层加密格式，支持导入私钥及完整账户清单；做 v1 向后兼容和云端读回校验。对多账户、多地址、不同派生路径做跨设备恢复测试。
4. **发布前验证**：Android Auto Backup 排除安全存储数据；iOS 使用预期的 Keychain 可访问级别；真机测试删除 App、换机恢复、备份冲突、旧版本迁移。云端无法恢复时不得覆盖唯一可用的旧备份。

安全存储和备份边界参考：[OWASP MASVS 存储要求](https://mas.owasp.org/MASVS/controls/MASVS-STORAGE-1/) · [OWASP 设备备份风险](https://mas.owasp.org/MASWE-0006/) · [Flutter 安全存储 Android 备份说明](https://pub.dev/packages/flutter_secure_storage#android)。
