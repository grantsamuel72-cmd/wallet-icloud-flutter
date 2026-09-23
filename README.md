# wallet_cloud_backup

Flutter Web3 钱包的云备份插件，一套 API，按平台自动选择存储：

| 平台 | 存储位置 | 用户侧前提 |
| --- | --- | --- |
| iOS 13+ | iCloud Drive，应用自己的 ubiquity container（`WalletBackups/`，Files App 不可见） | 已登录 iCloud 并开启 iCloud Drive |
| Android API 24+ | Google Drive 隐藏的 `appDataFolder`（其他应用和普通 Drive 列表都看不到） | 首次使用时选择 Google 账号并授权 |

其他平台调用 `WalletCloudBackup(...)` 会抛出 `UnsupportedError`。

推荐用法是 `MnemonicCloudBackup`：助记词在本机用用户设置的备份密码加密（Argon2id + AES-256-GCM），
上传的只有密文；[Wallet Core](https://github.com/grantsamuel72-cmd/wallet-core-flutter) 负责校验助记词，
并在每次恢复后确认助记词派生出的钱包没有变。明文助记词和密码不会离开设备。

## 安装

```yaml
dependencies:
  wallet_cloud_backup:
    path: ../wallet-icloud-flutter
```

开发使用 Flutter 3.44.8（Dart 3.12），项目根目录的 `.fvmrc` 已固定该版本，命令请用
`fvm flutter ...`。本插件没有自己的原生代码，原生能力来自 `wallet_core`、`icloud_storage_plus`
和 `google_sign_in`，宿主 App 构建时会自动注册。

`wallet_core` 以 git 依赖引入，固定在提交 `d93b9da594cc8ce4049dd687e03620727c88c149`。如果 App
自己也 `import 'package:wallet_core/wallet_core.dart'`，必须在 App 的 pubspec 里写**同一个 url 和
ref**，否则依赖解析会冲突：

```yaml
  wallet_core:
    git:
      url: https://github.com/grantsamuel72-cmd/wallet-core-flutter.git
      ref: d93b9da594cc8ce4049dd687e03620727c88c149
```

同时修改两个仓库时，可以建一个 `pubspec_overrides.yaml`（已加入 `.gitignore`）把 `wallet_core`
指向本地的 `../wallet-core-flutter`。

## 平台配置

### iOS：iCloud 与 Wallet Core

1. Apple Developer 中创建 iCloud Container，例如 `iCloud.com.example.wallet`，并关联到 App ID。
2. Xcode → Target → Signing & Capabilities → iCloud，勾选 **iCloud Documents**，选中该 Container。
3. `wallet_core` 通过 CocoaPods 引入 `TrustWalletCore 4.8.1`。第一次 `flutter pub get` 会自动生成
   `ios/Podfile`，把其中的 `platform :ios, '13.0'` 取消注释。其余插件继续走 Swift Package
   Manager，两者可以共存，`flutter build` / `flutter run` 会自动执行 `pod install`。

### Android：Google Drive

1. Google Cloud Console 中启用 **Google Drive API**。
2. 配置 OAuth 同意屏幕，添加 scope `https://www.googleapis.com/auth/drive.appdata`。
3. 创建 **Android** 类型的 OAuth Client：包名 + 签名证书 SHA-1。debug、release、
   Play 应用签名的 SHA-1 各需一个，缺失会表现为授权被"取消"。
4. `android/app/build.gradle` 中 `minSdk = 24` 或更高。

插件只做 Drive 授权，不做 Google 登录，所以 **不需要** `google-services.json` 或 `serverClientId`。

`google_sign_in` 每个进程只能初始化一次。如果 App 自己已经在做 Google 登录并调用了
`GoogleSignIn.instance.initialize`，请传 `GoogleDriveOptions(initializeGoogleSignIn: false)`，
避免重复初始化。

### Android：Wallet Core SDK

`wallet_core` 需要 Trust Wallet Core 的 Android SDK。本插件只用它的常用接口
（`WalletCore` / `HDWallet`），这些接口走官方 AAR 自带的 Java JNI 类，按源码看不需要开启
`TW_EXPORT_C_API` 的自编译 SDK（目前只用本机的自编译 SDK 实测过，官方 AAR 尚未实测）。
在 App 的 `android/local.properties`（不提交）里二选一：

```properties
# 官方 AAR（GitHub Packages，需要有 read:packages 权限的 token）
gpr.user=YOUR_GITHUB_USERNAME
gpr.key=YOUR_READ_PACKAGES_TOKEN

# 或者本地 Maven 仓库
walletCoreMavenRepository=/absolute/path/to/maven
walletCoreVersion=4.8.1
```

CI 上可以用环境变量 `GITHUB_USER` / `GITHUB_TOKEN`。如果 `settings.gradle` 使用了
`FAIL_ON_PROJECT_REPOS`，需要按 wallet-core-flutter 的 README 自己声明 Maven 仓库。

- **ABI**：`wallet_core` 默认只打包 `arm64-v8a`。其他 ABI（32 位手机、x86_64 模拟器）运行时会抛
  `WalletCoreUnavailableException`。要么用 `walletCoreAbis=arm64-v8a,armeabi-v7a,x86_64` 打包更多
  ABI，要么在 App 的 `defaultConfig.ndk.abiFilters` 里只保留 `arm64-v8a`。
- **工具链**：`wallet_core` 会编译一个 JNI 桥接库，需要 NDK 27.0.12077973 和 CMake。
- **包体**：Android 每个 ABI 约增加 17.6 MB，iOS 约增加 35 MB。

## 助记词加密备份（推荐）

```dart
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

// 整个 App 一个实例即可。
final cloud = WalletCloudBackup(
  iCloud: const ICloudOptions(containerId: 'iCloud.com.example.wallet'),
);
final backups = MnemonicCloudBackup(cloud);

// 1. 用户点"开启云备份"时连接。Android 可能弹出账号选择和授权页。
if (!await cloud.connect(interactive: true)) {
  return; // iOS：未登录 iCloud 或关闭了 iCloud Drive；Android：用户取消授权。
}

// 2. 备份。每个钱包一个文件，重复备份会覆盖同一个钱包的旧文件。
await backups.backupWallet(
  walletId: wallet.uuid,     // 不能含敏感信息，UTF-8 最长 100 字节
  wallet: hdWallet,          // Wallet Core 的 HDWallet，不会被释放
  password: backupPassword,  // 至少 8 个字符
  label: '主钱包',            // 可选，明文保存，只用于恢复页显示
);
// 或者直接传助记词：backups.backupMnemonic(walletId: ..., mnemonic: ..., password: ...)

// 3. 新设备上恢复。
for (final entry in await backups.listRestorable()) {
  if (!entry.isRestorable) continue; // entry.error 说明原因
  final restored = await backups.restoreWallet(entry.walletId, password: backupPassword);
  try {
    // 使用 restored（HDWallet），或 restoreMnemonic() 直接拿助记词保存到本地安全存储
  } finally {
    await restored.dispose();
  }
}
```

其他方法：

- `verifyPassword(walletId, password: ...)`：只校验密码，适合定期提醒用户"还记得备份密码吗"。
- `changePassword(walletId, currentPassword: ..., newPassword: ...)`：重新加密，标签保持不变。
- `isWalletCoreAvailable()`：检查当前构建里 Wallet Core 能否运行，例如 Android ABI 不匹配时返回 false。

`backupMnemonic` 会先在内存里解密一次自检，上传后再读回来比对，都通过才返回。如果上传成功但读回
失败，抛出的 `CloudStorageException` 会注明"可能已替换旧备份"——这时先用 `verifyPassword`
确认云端是哪个版本，再决定怎么提示用户（改密码时尤其如此）。

### 加密与安全

- **密钥派生**：Argon2id（RFC 9106 推荐参数：64 MiB、3 轮、4 并行），随机 16 字节 salt，在后台
  isolate 里运行。参数随每个备份保存，以后可以调高而不影响旧备份。读取时参数超出
  `BackupKdfParameters.minimum`～`maximum`，或内存×轮数超过推荐值的 4 倍，会在派生前直接拒绝，
  限制恶意文件能占用的内存和时间。
- **加密**：HKDF-SHA256 从主密钥分出 AES-256-GCM 密钥和 16 字节的密码校验值。walletId、创建时间、
  标签、KDF 参数、校验值都作为附加认证数据，被改动或换到别的钱包文件都会解密失败。
- **明文内容**：云端文件里只有 walletId、标签、创建时间、KDF 参数和密文。明文填充到 512 字节，
  看不出是 12 个词还是 24 个词。地址只存在密文里，用于恢复后确认派生出的钱包一致。
- **错误区分**：密码校验值不对 → `WrongBackupPasswordException`；密码对但密文被改 →
  `BackupIntegrityException`。能改写云端文件的人也可以通过改 KDF 参数制造"密码错误"，但拿不到内容。
- **密码是唯一防线**：云盘账号被盗时，攻击者可以离线暴力破解。插件只强制最短长度（默认 8，不能
  设得更低），请在 UI 里加强度提示。忘记密码无法恢复。
- **助记词输入框要关掉键盘学习**：`autocorrect`、`enableSuggestions`、
  `enableIMEPersonalizedLearning` 三个开关默认全开，用户手敲的真实助记词会进入系统输入法的
  学习词库和候选栏。`example/lib/main.dart` 演示了正确写法。
- **BIP39 passphrase（第 25 个词）不会备份**，恢复时通过 `restoreWallet(bip39Passphrase: ...)` 传入。
- **密码不做 Unicode 规范化**，按输入的 UTF-8 字节原样使用。同一平台的键盘输入基本都是 NFC，
  但如果允许粘贴或跨系统输入带重音的字符，请在 App 里统一规范化后再传入。
- **旧版本**：改密码后，Google Drive 的修订历史和 iCloud 的历史版本里可能仍有旧密文，旧密码泄露时
  应视为助记词可能泄露。
- 耗时：派生一次在 M 系列 Mac 上约 0.2 秒，手机上预计 0.5～1.5 秒；备份和恢复各派生一次。

为什么不直接上传 Wallet Core 的 `TWStoredKey` Keystore：导入助记词时 Wallet Core 只能用较弱的
scrypt 参数（N=16384）；Android 上 `TWStoredKey*` 属于完整 C 接口，官方 AAR 不导出，只有自编译的
`TW_EXPORT_C_API` SDK 能用；而且密码错误和文件损坏都返回 null，无法区分。

## 底层 API：自己加密的 Keystore

不需要 Wallet Core 加密时，可以直接用 `WalletCloudBackup` 存取任意已加密的 JSON：

```dart
final backup = await WalletBackup.create(
  walletId: wallet.uuid,
  encryptedKeystore: myEncryptedKeystoreJson,
);
await cloud.backup(backup);
final restored = await cloud.restore(wallet.uuid);   // 校验 checksum 与 walletId
await cloud.delete(wallet.uuid);
await cloud.disconnect(); // Android：清掉本地令牌并退出；iOS 无操作
```

备份文档结构：

```json
{
  "formatVersion": 1,
  "walletId": "public-wallet-id",
  "encryptedKeystore": {},
  "createdAt": "2026-09-22T08:00:00.000Z",
  "checksum": "sha256..."
}
```

`checksum` 用于发现损坏或非预期修改，不能替代 Keystore 自身的认证加密。恢复时还会校验文档里的
`walletId` 是否与请求的一致。助记词备份也是这个结构，加密内容放在 `encryptedKeystore` 里。

## 云盘连接

`connect()`（非交互）不会弹任何 UI。`backup`、`restore` 等操作会自动做一次非交互连接；
如果需要用户授权，会抛出 `CloudAuthenticationException`，此时应在用户点击时调用
`connect(interactive: true)`。用户在授权页点"取消"时返回 `false`，其他授权失败抛出
`CloudAuthenticationException`。注意 SHA-1 或包名配置错误时 Google 也可能报告为"取消"，
调试时如果授权后一直返回 `false`，先检查 OAuth Client 配置。

Android 的访问令牌约 1 小时过期。插件会在 45 分钟后主动刷新，遇到 401 时会作废旧令牌并重试一次，
调用方不用处理。

`disconnect()` 只清除本地令牌，Google 那边的 Drive 授权仍然有效，之后的 `connect()` 或任何操作都会
静默拿到同一账号的新令牌。所以"关闭云备份"要靠 App 自己的开关来控制；彻底撤销授权需要用户在
Google 账号的"第三方应用访问权限"里移除。目前也不支持在 App 内切换 Google 账号。

单次云端调用默认 60 秒超时（`GoogleDriveBackupStore.requestTimeout` /
`ICloudBackupStore.operationTimeout`），超时抛 `CloudStorageException`，避免离线时一直卡住。

### 备份文件在哪里，为什么看不见

iOS 上文件写在 `<ubiquity container>/WalletBackups/wallet-<hex>.json`。默认的 `folder` 没有
`Documents/` 前缀，所以 **Files App、iCloud.com 网页、"iCloud 云盘"列表里都不会显示它**——这是
有意的：能在 Files App 里看到，就能在 Files App 里删掉，而这个文件往往是用户恢复钱包的唯一途径。

确认备份确实存在，有四种办法：

1. `backupMnemonic` 返回即证明。它上传后会完整读回一次并比对 checksum，不一致就抛
   `CloudStorageException`。
2. `cloud.store.list()` 直接列出容器里的文件（名称、字节数、修改时间）。`example/` 的"诊断"
   按钮演示了这个用法。
3. Mac 上用同一个 Apple ID 登录后直接看：
   `~/Library/Mobile Documents/iCloud~com~example~wallet/WalletBackups/`
   （容器 id 里的 `.` 要换成 `~`）。
4. iPhone 设置 → Apple ID → iCloud → 管理账户存储，能看到这个 App 占用的空间。

真想让用户在 Files App 里看到，需要同时做两件事：`folder` 改成 `Documents/...`，并在 App 的
`Info.plist` 里加 `NSUbiquitousContainers` 且 `NSUbiquitousContainerIsDocumentScopePublic`
为 `true`。少任何一个都不会显示。

## 新设备上的 iCloud 同步

新设备首次启动时，iCloud 可能还没把备份目录同步下来：

- 恢复时本地找不到文件，会通过 iCloud 元数据查询等待最多 `ICloudOptions.syncTimeout`
  （默认 10 秒），文件出现后自动下载。设为 `Duration.zero` 可关闭等待。
- `list()` / `listRestorable()` 在同步完成前可能为空。恢复页建议提供"刷新"，不要一次查不到就提示
  "没有备份"。

## iCloud 冲突（仅 iOS）

两台设备离线时各自备份同一个钱包，iCloud 会保留多个版本。Android 上 `listConflicts` 返回空列表、
`resolveConflicts` 什么都不做，`readConflictVersion` 抛 `UnsupportedError`。

```dart
final versions = await cloud.listConflicts(walletId);
for (final version in versions) {
  final candidate = await cloud.readConflictVersion(walletId, version.id);
  // 比较 candidate.createdAt 等信息；要保留它，就 await cloud.backup(candidate);
}
await cloud.resolveConflicts(
  walletId,
  reviewedVersionIds: {for (final v in versions) v.id},
  removeOtherVersions: true,
);
```

`resolveConflicts` 执行前会重新列出版本。如果出现了不在 `reviewedVersionIds` 里的新版本，
会抛出 `BackupConflictException` 且不做任何修改，避免未检查过的版本被删掉。iCloud 的"标记已解决"
会作用于当时所有未解决版本，所以在重新列出和标记之间仍有极短的窗口无法完全排除。

## 错误处理

运行时错误都是 `WalletCloudBackupException` 或其子类，原始异常在 `cause` 字段里；异常信息里不会
出现助记词或密码。`LocalBackupCache` 是例外：它直接透传 `flutter_secure_storage` 的
`PlatformException`，不做包装。

调用方的编程错误保持原类型：传入已 `dispose` 的 `HDWallet` 抛 `StateError`，Wallet Core 拒绝的
BIP39 passphrase（如含 NUL）抛 `ArgumentError`，不是纯文件名的 `fileName`（直接使用
`ICloudBackupStore` / `GoogleDriveBackupStore` 时）也抛 `ArgumentError`。

| 异常 | 含义 |
| --- | --- |
| `WrongBackupPasswordException` | 备份密码不对 |
| `WeakBackupPasswordException` | 新密码太短（`minLength`） |
| `InvalidMnemonicException` | 助记词不是有效的 BIP39 |
| `WalletCoreUnavailableException` | 当前构建里 Wallet Core 不能运行（ABI 不匹配、插件未注册） |
| `BackupNotFoundException` | 该钱包没有备份 |
| `CloudAuthenticationException` | Android 未授权、授权被撤销或配置错误 |
| `CloudUnavailableException` | iOS 未登录 iCloud、iCloud Drive 关闭或 Container 未配置 |
| `CloudStorageException` | 网络、服务端或文件协调失败，或上传后读回不一致，可重试 |
| `BackupFormatException` | 文档格式错误、walletId / 标签非法、KDF 参数越界或超过大小上限（默认 10 MiB） |
| `BackupIntegrityException` | 校验和不匹配、密文被改、文件属于其他钱包，或恢复出的助记词派生出别的钱包 |
| `BackupConflictException` | 解决冲突时发现了未检查的新版本 |

## 可选：AES-256-GCM

自己实现加密时可以用 `AesGcmBackupCipher`。key 必须先由用户密码通过 Argon2id/scrypt 派生，派生参数
（算法、salt、成本参数）必须通过 `keyDerivation` 随密文一起保存，否则换设备后无法重新派生 key；
`aad` 可选，会被认证但不会保存：

```dart
final payload = await AesGcmBackupCipher().encrypt(
  clearKeystoreBytes,
  key: derived32ByteSecretKey,
  keyDerivation: {
    'algorithm': 'argon2id',
    'salt': base64Encode(salt),
    'memoryKiB': 65536,
    'iterations': 3,
    'parallelism': 4,
  },
  aad: utf8.encode(walletId),
);
```

`keyDerivation` 里不能放密码或 key。

## 本机缓存

`LocalBackupCache` 基于 `flutter_secure_storage`，只适合保存本机的提示信息或缓存值，
不能作为跨设备恢复的唯一解密来源。

两端的默认行为都需要注意：

- **iOS**：默认 `KeychainAccessibility.unlocked`（非 `ThisDeviceOnly`），这类 Keychain 项**会**进入
  加密的设备备份，并在恢复到新机时一起还原。要真正绑定本机，显式传
  `IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device)`。
- **Android**：默认 `resetOnError: true`，解密失败时 `read()` **不抛异常**，而是静默删掉该键并返回
  null，调用方无法区分"从没写过"和"被清掉了"。要感知失败请传 `AndroidOptions(resetOnError: false)`。
  另外建议关闭 Auto Backup 或排除其数据，避免恢复后 Keystore key 不匹配。

## 示例与测试

`example/` 是可运行的 App，默认"演示模式"把备份存在内存里，不需要云盘配置就能体验备份、列出和恢复。
`example/integration_test/` 在真机或模拟器上用真实 Wallet Core 和真实 Argon2id 参数验证 BIP39 测试向量：

```sh
cd example
fvm flutter test integration_test -d <device>
```

## 已知限制

- `wallet_core` 的 Android 插件使用了 Kotlin Gradle Plugin，Flutter 3.44 会提示"未来版本将无法构建"；
  iOS 插件只支持 CocoaPods，Flutter 也提示未来会报错。两者都需要在 wallet-core-flutter 里修改。
- `wallet_core` 是固定 SHA 的 git 依赖，升级时同时修改本插件和 App 的 pubspec，并重新跑测试。

## 参考

- [wallet-core-flutter](https://github.com/grantsamuel72-cmd/wallet-core-flutter)
- [icloud_storage_plus](https://pub.dev/packages/icloud_storage_plus)
- [google_sign_in](https://pub.dev/packages/google_sign_in)
- [Google Drive appDataFolder](https://developers.google.com/workspace/drive/api/guides/appdata)
- [RFC 9106 Argon2](https://www.rfc-editor.org/rfc/rfc9106)
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
