## 0.3.1

Fixes:

- Google Drive `write` no longer reports a failure when it cannot delete a duplicate left by
  another device: the new bytes are already stored by then, and a 404 from that cleanup surfaced
  as `BackupNotFoundException` for a backup that had just been written.
- Concurrent Google Drive operations no longer discard each other's access token. A request whose
  401 arrives after a sibling already replaced the token now uses the replacement, and one that
  arrives while the replacement is still being fetched waits for it instead of being handed the
  dead token back.
- Listing iCloud backups no longer fails outright when the container holds a file whose name the
  plugin refuses to look up; it is listed without its attributes.
- `ICloudBackupStore.read` measures its sync wait on a monotonic clock, so a clock correction
  during the wait cannot stretch or cut it.

- `ICloudBackupStore` rejected no file name at all, so `delete('')` addressed the backup folder
  itself, which `icloud_storage_plus` deletes recursively — one call could wipe every backup in the
  container. Both backends now reject a name that is not a plain file name, and both report it
  through the returned future.
- Google Drive `write` now deletes the duplicates it leaves behind when two offline devices each
  created a file with the same name, so a wallet keeps a single backup and no older ciphertext
  outlives a password change.
- `list()` returns the same order on both backends: Google Drive sorts locally as well as asking the
  server to (picking between same-named copies still follows the server's order), and iCloud reads attributes off the file system for files the Spotlight index has not
  indexed yet, so this device's own fresh writes are no longer sorted last without a date or size.
- Concurrent Google Drive operations share one authorization instead of each requesting a token.
- `MnemonicCloudBackup.listRestorable` reads up to four wallets at a time instead of one after
  another, and keeps the order, so a restore screen waits for a quarter as many round trips (Drive)
  or sync timeouts (iCloud) as it has wallets.
- `ICloudBackupStore.read` queries iCloud metadata once per call instead of once per retry; repeating
  it only re-answered a question already answered and ate into `syncTimeout`.
- `ICloudBackupStore.write` runs its metadata lookup through the same guard as every other call, so
  it cannot hang past `operationTimeout` or leak a provider exception out of the store's contract.
- The Argon2id isolate clears its own copy of the password, which the caller's wipe cannot reach.

Tests:

- The backup file name encoding and the mnemonic header's authenticate-everything-unknown rule are
  now frozen by tests. Both are cross-version contracts that a round-trip test cannot protect:
  changing them left the suite green while orphaning every backup already in the cloud.
- Google Drive's two read-side size checks, and iCloud's on all three read paths, are covered.
- Four assertions that could never fail were replaced with ones that can: two "the existing backup
  survived" checks that ran against an empty store, one ordering check whose two files had the same
  size, and the Argon2id wipe check, which compared two buffers that would both have been wiped.

Docs:

- Said what the conflict methods actually do on Android: `listConflicts` returns an empty list,
  `resolveConflicts` does nothing, and `readConflictVersion` throws `UnsupportedError`. The README
  and two of the three dartdocs had flattened this into "empty list or nothing".
- `CloudBackupStore.write` and `read` document what happens when a provider holds two files of the
  same name, which the 0.3.1 cleanup made part of the contract.
- The example turns off `autocorrect`, `enableSuggestions` and `enableIMEPersonalizedLearning` on
  its mnemonic field, and the README says why: all three default to on, so a real phrase typed into
  a wallet app reaches the keyboard's learned vocabulary.
- The example's iCloud container constant matches its entitlements, so turning demo mode off can
  actually connect, and a "诊断" button lists what is really in the container — a backup stored
  outside `Documents/` is invisible to the Files app by design, which reads like a failure.
- The README says where the backup file lives, why nothing shows up in the Files app or on
  iCloud.com, and four ways to confirm it is there.

- `CloudBackupStore` and `WalletCloudBackupException` documented that caller mistakes keep their
  usual types, matching what the README already said.
- `assertPlainBackupFileName` and `compareBackupsNewestFirst` are exported: a custom
  `CloudBackupStore` needs both to answer like the built-in backends.
- Corrected what the README says about `LocalBackupCache`. On iOS its values do travel to a new
  device in an encrypted device backup unless `KeychainAccessibility.unlocked_this_device` is
  passed, and on Android a failed read deletes the value and returns null instead of throwing.

## 0.3.0

- Adds `wallet_core` (github.com/grantsamuel72-cmd/wallet-core-flutter, pinned to `d93b9da`)
  as a git dependency.
- New `MnemonicCloudBackup`: password-protected BIP39 mnemonic backups on top of
  `WalletCloudBackup` — `backupMnemonic`, `backupWallet(HDWallet)`, `listRestorable`,
  `restoreMnemonic`, `restoreWallet`, `verifyPassword`, `changePassword`, `isWalletCoreAvailable`.
  - Encryption in Dart: Argon2id (64 MiB, t=3, p=4 by default, stored per backup and bounded when
    read) → HKDF-SHA256 → AES-256-GCM with the wallet id and header as associated data; plaintext
    padded to 512 bytes. A key-check value separates a wrong password from a tampered file.
  - Wallet Core's high-level API validates mnemonics and checks after every restore that the phrase
    still derives the Ethereum address recorded at backup time. The full C API (`TWStoredKey`) is
    not used, so the official Trust Wallet Core SDK is enough on Android.
  - Uploads are self-checked in memory and read back before `backupMnemonic` returns.
- New exceptions: `WrongBackupPasswordException`, `WeakBackupPasswordException`,
  `InvalidMnemonicException`, `WalletCoreUnavailableException`.
- New `BackupKdfParameters`; `AesGcmBackupCipher.encrypt/decrypt` accept optional `aad`.
- `example/` is now a runnable app with an in-memory demo mode and on-device integration tests.
- Envelope `formatVersion` stays 1; 0.2.0 backups and APIs are unchanged.
- Known: `wallet_core_android` applies the Kotlin Gradle Plugin and `wallet_core_darwin` is
  CocoaPods-only, both of which Flutter 3.44 warns about.

## 0.2.0

Breaking changes:

- `WalletCloudBackup(...)` now selects the backend by platform: iCloud on iOS, Google Drive
  `appDataFolder` on Android. Other platforms throw `UnsupportedError`. Use
  `WalletCloudBackup.withStore` for a custom store.
- Backups are stored per wallet (`restore(walletId)`, `delete(walletId)`); the shared
  `wallet-backup.json` default is gone, so one wallet no longer overwrites another.
- `CloudBackupStore.isAvailable` is replaced by `connect({interactive})` and `disconnect()`.
- `GoogleDriveAuthorizer` is removed; `GoogleDriveBackupStore` handles authorization itself,
  requests only `drive.appdata`, and needs no `serverClientId` on Android.
- `AesGcmBackupCipher.encrypt` requires `keyDerivation` parameters, stored with the ciphertext.
- iCloud conflicts are resolved with `resolveConflicts(reviewedVersionIds: ...)`, which refuses to
  resolve when an unreviewed version has appeared.
- Requires Flutter 3.44 / Dart 3.12; declares Android and iOS only.
- Drops `cryptography_flutter`, whose Kotlin Gradle Plugin usage future Flutter versions reject;
  AES-GCM now uses the pure-Dart `cryptography` implementation (same ciphertext format).

Fixes:

- iCloud availability no longer throws on unsupported platforms.
- Google Drive access tokens are refreshed before expiry and after a 401 response.
- `google_sign_in` is initialized at most once per process, or not at all when the app owns it.
- Provider errors are mapped to `WalletCloudBackupException` subclasses.
- iCloud restore waits for sync on a new device and retries until the local placeholder exists;
  `list()` shows both this device's writes and files known only to iCloud metadata.
- A cancelled Android consent screen makes `connect(interactive: true)` return false.
- `PlatformException`, TLS and malformed-response errors are wrapped; every cloud call has a timeout.
- Wallet ids with unpaired UTF-16 surrogates are rejected instead of colliding on one file.

## 0.1.0

- Initial release with iCloud Drive and Google Drive `appDataFolder` backends.
- Backup envelope validation and SHA-256 checksums.
- Optional local token/cache storage adapter backed by platform secure storage.
