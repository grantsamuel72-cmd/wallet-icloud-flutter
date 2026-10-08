import 'dart:math';

import 'package:drift/drift.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/data/wallet_database.dart';
import 'package:wallet_cloud_backup_example/data/wallet_secret_store.dart';
import 'package:wallet_cloud_backup_example/domain/wallet_models.dart';
import 'package:wallet_core/wallet_core.dart';

class CreatedWallet {
  const CreatedWallet(this.id, this.mnemonic);

  final String id;
  final String? mnemonic;
}

enum BackupHdResult { uploaded, alreadyBackedUp }

class WalletRepository {
  WalletRepository({
    required this.database,
    required this.secrets,
    required this.core,
    required this.backups,
    Random? random,
  }) : _random = random ?? Random.secure();

  final WalletDatabase database;
  final WalletSecretStore secrets;
  final WalletCore core;
  MnemonicCloudBackup backups;
  final Random _random;
  String _cloudScope = 'default';

  void useCloud(MnemonicCloudBackup service, String scope) {
    backups = service;
    _cloudScope = scope;
  }

  String _id() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<List<StoredWallet>> listWallets() async {
    final rows = await database.select(database.walletRows).get();
    final result = <StoredWallet>[];
    for (final row in rows) {
      if (row.state == 'deleting') {
        await _finishDeletion(row);
        continue;
      }
      final missingSecret =
          row.secretRef != null && !await secrets.contains(row.secretRef!);
      if (missingSecret) {
        await (database.update(database.walletRows)
              ..where((t) => t.id.equals(row.id)))
            .write(const WalletRowsCompanion(state: Value('needs_restore')));
      }
      final accounts = await (database.select(
        database.accountRows,
      )..where((t) => t.walletId.equals(row.id))).get();
      final addresses = <StoredAddress>[];
      for (final account in accounts) {
        final chain = WalletChain.values.firstWhere(
          (c) => c.family == account.chainFamily,
        );
        final entries = await (database.select(
          database.addressRows,
        )..where((t) => t.accountId.equals(account.id))).get();
        for (final entry in entries) {
          addresses.add(
            StoredAddress(
              chain: chain,
              address: entry.address,
              path: entry.derivationPath,
              index: entry.addressIndex,
            ),
          );
        }
      }
      final status = await (database.select(
        database.backupStatusRows,
      )..where((t) => t.walletId.equals(row.id))).getSingleOrNull();
      result.add(
        StoredWallet(
          id: row.id,
          name: row.name,
          kind: WalletKind.fromDatabase(row.kind),
          state: missingSecret ? 'needs_restore' : row.state,
          backupState: status?.scope == _cloudScope ? status!.state : 'none',
          lastBackedUpAt:
              status?.scope == _cloudScope && status?.state == 'verified'
              ? status?.lastVerifiedAt
              : null,
          addresses: List<StoredAddress>.unmodifiable(addresses),
        ),
      );
    }
    return List<StoredWallet>.unmodifiable(result);
  }

  Future<CreatedWallet> createHd({
    required String name,
    String? mnemonic,
    String? walletId,
  }) async {
    final cleanName = _name(name);
    final id = walletId ?? _id();
    if (await _wallet(id) != null) {
      throw StateError('This wallet already exists locally.');
    }
    final wallet = mnemonic == null
        ? await core.createWallet(strength: 128)
        : await core.importWallet(mnemonic: mnemonic);
    try {
      final phrase = await wallet.getMnemonic();
      final derived = <(WalletChain, String, String)>[];
      for (final chain in WalletChain.values) {
        final path = (await core.getCoinInfo(chain.coinType)).derivationPath;
        if (path.isEmpty) {
          throw StateError('Wallet Core did not provide a derivation path.');
        }
        derived.add((
          chain,
          path,
          await wallet.getAddress(chain.coinType, derivationPath: path),
        ));
      }
      final ref = 'wallet/$id/mnemonic';
      await secrets.write(ref, phrase);
      try {
        await database.transaction(() async {
          await _insertWallet(
            id: id,
            kind: WalletKind.hd,
            name: cleanName,
            secretRef: ref,
          );
          for (final (chain, path, address) in derived) {
            await _insertAccountAddress(
              id,
              chain,
              address,
              path: path,
              index: 0,
            );
          }
        });
      } catch (_) {
        await secrets.delete(ref);
        rethrow;
      }
      return CreatedWallet(id, mnemonic == null ? phrase : null);
    } finally {
      await wallet.dispose();
    }
  }

  Future<CreatedWallet> importPrivateKey({
    required String name,
    required String keyHex,
  }) async {
    final cleanName = _name(name);
    final normalized = keyHex
        .trim()
        .replaceFirst(RegExp(r'^0[xX]'), '')
        .toLowerCase();
    final bytes = _decodeKey(normalized);
    final derived = <(WalletChain, String)>[];
    try {
      for (final chain in WalletChain.values) {
        derived.add((
          chain,
          await core.deriveAddress(privateKey: bytes, coin: chain.coinType),
        ));
      }
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
    final id = _id();
    final ref = 'wallet/$id/private_key';
    await secrets.write(ref, normalized);
    try {
      await database.transaction(() async {
        await _insertWallet(
          id: id,
          kind: WalletKind.importedKey,
          name: cleanName,
          secretRef: ref,
        );
        for (final (chain, address) in derived) {
          await _insertAccountAddress(id, chain, address);
        }
      });
    } catch (_) {
      await secrets.delete(ref);
      rethrow;
    }
    return CreatedWallet(id, null);
  }

  Future<CreatedWallet> addWatchOnly({
    required String name,
    required WalletChain chain,
    required String address,
  }) async {
    final cleanName = _name(name);
    final cleanAddress = address.trim();
    if (!await core.isValidAddress(cleanAddress, chain.coinType)) {
      throw const FormatException('Address is invalid for the selected chain.');
    }
    final id = _id();
    await database.transaction(() async {
      await _insertWallet(id: id, kind: WalletKind.watchOnly, name: cleanName);
      await _insertAccountAddress(id, chain, cleanAddress);
    });
    return CreatedWallet(id, null);
  }

  Future<void> addHdAddress(
    String walletId,
    WalletChain chain,
    int index,
  ) async {
    if (index < 0 || index > 0x7fffffff) throw RangeError.value(index, 'index');
    final row = await _wallet(walletId);
    if (row == null ||
        row.kind != WalletKind.hd.databaseValue ||
        row.state != 'ready') {
      throw StateError('An available HD wallet is required.');
    }
    final phrase = await secrets.read(row.secretRef!);
    if (phrase == null) {
      throw StateError('The mnemonic is missing; restore this wallet first.');
    }
    final account =
        await (database.select(database.accountRows)..where(
              (t) =>
                  t.walletId.equals(walletId) &
                  t.chainFamily.equals(chain.family),
            ))
            .getSingleOrNull();
    if (account == null) throw StateError('This chain is not configured.');
    final first =
        await (database.select(database.addressRows)..where(
              (t) => t.accountId.equals(account.id) & t.isPrimary.equals(true),
            ))
            .getSingle();
    final base = first.derivationPath;
    if (!base.endsWith('/0')) {
      throw StateError('Unsupported derivation path: $base');
    }
    final path = '${base.substring(0, base.length - 1)}$index';
    if (await (database.select(database.addressRows)..where(
              (t) =>
                  t.accountId.equals(account.id) &
                  t.derivationPath.equals(path),
            ))
            .getSingleOrNull() !=
        null) {
      throw StateError('This address index already exists.');
    }
    final wallet = await core.importWallet(mnemonic: phrase);
    try {
      final address = await wallet.getAddress(
        chain.coinType,
        derivationPath: path,
      );
      await database.transaction(() async {
        await database
            .into(database.addressRows)
            .insert(
              AddressRowsCompanion.insert(
                id: _id(),
                accountId: account.id,
                derivationPath: Value(path),
                changeIndex: const Value(0),
                addressIndex: Value(index),
                address: address,
                addressNormalized: _normalizeAddress(chain, address),
              ),
            );
      });
    } finally {
      await wallet.dispose();
    }
  }

  Future<void> verifyLocalWallet(String walletId) async {
    final row = await _wallet(walletId);
    if (row == null || row.state != 'ready') {
      throw StateError('Wallet is not available.');
    }
    final accounts = await (database.select(
      database.accountRows,
    )..where((t) => t.walletId.equals(walletId))).get();
    if (row.kind == WalletKind.watchOnly.databaseValue) {
      for (final account in accounts) {
        final chain = WalletChain.values.firstWhere(
          (c) => c.family == account.chainFamily,
        );
        final addresses = await (database.select(
          database.addressRows,
        )..where((t) => t.accountId.equals(account.id))).get();
        for (final entry in addresses) {
          if (!await core.isValidAddress(entry.address, chain.coinType)) {
            throw StateError('A stored watch-only address is invalid.');
          }
        }
      }
      return;
    }
    final secret = await secrets.read(row.secretRef!);
    if (secret == null) throw StateError('The wallet secret is missing.');
    final HDWallet? hd = row.kind == WalletKind.hd.databaseValue
        ? await core.importWallet(mnemonic: secret)
        : null;
    final Uint8List? key = hd == null ? _decodeKey(secret) : null;
    try {
      for (final account in accounts) {
        final chain = WalletChain.values.firstWhere(
          (c) => c.family == account.chainFamily,
        );
        final addresses = await (database.select(
          database.addressRows,
        )..where((t) => t.accountId.equals(account.id))).get();
        for (final entry in addresses) {
          final derived = hd != null
              ? await hd.getAddress(
                  chain.coinType,
                  derivationPath: entry.derivationPath,
                )
              : await core.deriveAddress(
                  privateKey: key!,
                  coin: chain.coinType,
                );
          if (_normalizeAddress(chain, derived) != entry.addressNormalized) {
            throw StateError(
              'Stored address does not match the wallet secret.',
            );
          }
        }
      }
    } finally {
      key?.fillRange(0, key.length, 0);
      await hd?.dispose();
    }
  }

  Future<BackupHdResult> backupHd(
    String walletId,
    String password, {
    bool useNewPassword = false,
  }) async {
    final row = await _wallet(walletId);
    if (row == null ||
        row.kind != WalletKind.hd.databaseValue ||
        row.state != 'ready') {
      throw StateError(
        'Only an available HD wallet can use this backup format.',
      );
    }
    await verifyLocalWallet(walletId);
    final phrase = await secrets.read(row.secretRef!);
    if (phrase == null) throw StateError('The mnemonic is missing.');
    final tronAccount =
        await (database.select(database.accountRows)..where(
              (t) =>
                  t.walletId.equals(walletId) &
                  t.chainFamily.equals(WalletChain.tron.family),
            ))
            .getSingle();
    final tron =
        await (database.select(database.addressRows)..where(
              (t) =>
                  t.accountId.equals(tronAccount.id) & t.isPrimary.equals(true),
            ))
            .getSingle();
    // Always check the cloud: a local status can be stale after a reinstall,
    // account switch, or deletion on another device.
    WalletBackup? existing;
    try {
      existing = await backups.cloud.restore(walletId);
    } on BackupNotFoundException {
      // This wallet has no cloud backup yet.
    }
    if (existing != null) {
      final cloudPhrase = await backups.restoreMnemonic(
        walletId,
        password: password,
      );
      if (cloudPhrase != phrase) {
        throw StateError('云端已有同 ID 的不同钱包备份，已停止上传以避免覆盖。');
      }
      await _markBackupVerified(
        walletId,
        existing.checksum,
        existing.createdAt,
      );
      return BackupHdResult.alreadyBackedUp;
    }

    // Normal additional backups use a password that opens an existing backup.
    // Explicit recovery mode creates only this new backup under a new password.
    if (!useNewPassword) {
      final entries = await backups.listRestorable();
      if (entries.any((entry) => entry.isRestorable)) {
        var accepted = false;
        for (final entry in entries.where((entry) => entry.isRestorable)) {
          if (await backups.verifyPassword(
            entry.walletId,
            password: password,
          )) {
            accepted = true;
            break;
          }
        }
        if (!accepted) throw const WrongBackupPasswordException();
      }
    }

    try {
      await backups.backupMnemonic(
        walletId: walletId,
        mnemonic: phrase,
        password: password,
        label: row.name,
        tronAddress: tron.address,
      );
      final stored = await backups.cloud.restore(walletId);
      await _markBackupVerified(walletId, stored.checksum, stored.createdAt);
      return BackupHdResult.uploaded;
    } on WalletCloudBackupException {
      // A timeout can happen after the provider committed the upload. Check
      // that the exact wallet is now readable before offering a retry.
      try {
        final stored = await backups.cloud.restore(walletId);
        final cloudPhrase = await backups.restoreMnemonic(
          walletId,
          password: password,
        );
        if (cloudPhrase == phrase) {
          await _markBackupVerified(
            walletId,
            stored.checksum,
            stored.createdAt,
          );
          return BackupHdResult.uploaded;
        }
      } on Exception {
        // Keep the previous confirmed state when cloud verification is uncertain.
      }
      rethrow;
    }
  }

  Future<void> _markBackupVerified(
    String walletId,
    String checksum,
    DateTime backedUpAt,
  ) async {
    await (database.update(
      database.backupStatusRows,
    )..where((t) => t.walletId.equals(walletId))).write(
      BackupStatusRowsCompanion(
        state: const Value('verified'),
        remoteChecksum: Value(checksum),
        lastVerifiedAt: Value(backedUpAt.toUtc()),
        scope: Value(_cloudScope),
      ),
    );
  }

  Future<List<RestorableWallet>> listCloudWallets() => backups.listRestorable();

  Future<void> deleteCloudBackup(RestorableWallet entry) async {
    // Verify the record still exists under the currently authorized account.
    await backups.cloud.restore(entry.walletId);
    try {
      await backups.cloud.delete(entry.walletId);
    } on WalletCloudBackupException {
      var confirmedDeleted = false;
      try {
        await backups.cloud.restore(entry.walletId);
      } on BackupNotFoundException {
        // A timeout occurred after the provider committed the deletion.
        confirmedDeleted = true;
      }
      if (!confirmedDeleted) rethrow;
    }
    if (await _wallet(entry.walletId) != null) {
      await (database.update(database.backupStatusRows)..where(
            (t) =>
                t.walletId.equals(entry.walletId) & t.scope.equals(_cloudScope),
          ))
          .write(const BackupStatusRowsCompanion(state: Value('none')));
    }
  }

  Future<void> restoreHd(RestorableWallet entry, String password) async {
    if (!entry.isRestorable) {
      throw StateError('This cloud entry cannot be restored.');
    }
    final phrase = await backups.restoreMnemonic(
      entry.walletId,
      password: password,
    );
    final existing = await _wallet(entry.walletId);
    if (existing == null) {
      await createHd(
        name: entry.label ?? '恢复的钱包',
        mnemonic: phrase,
        walletId: entry.walletId,
      );
    } else {
      if (existing.kind != WalletKind.hd.databaseValue ||
          existing.secretRef == null ||
          await secrets.contains(existing.secretRef!)) {
        throw StateError('A usable wallet with this ID already exists.');
      }
      final wallet = await core.importWallet(mnemonic: phrase);
      try {
        final accounts = await (database.select(
          database.accountRows,
        )..where((t) => t.walletId.equals(entry.walletId))).get();
        for (final account in accounts) {
          final chain = WalletChain.values.firstWhere(
            (c) => c.family == account.chainFamily,
          );
          final addresses = await (database.select(
            database.addressRows,
          )..where((t) => t.accountId.equals(account.id))).get();
          for (final address in addresses) {
            final derived = await wallet.getAddress(
              chain.coinType,
              derivationPath: address.derivationPath,
            );
            if (_normalizeAddress(chain, derived) !=
                address.addressNormalized) {
              throw StateError(
                'Cloud mnemonic does not match a stored address.',
              );
            }
          }
        }
      } finally {
        await wallet.dispose();
      }
      await secrets.write(existing.secretRef!, phrase);
      try {
        await (database.update(database.walletRows)
              ..where((t) => t.id.equals(entry.walletId)))
            .write(const WalletRowsCompanion(state: Value('ready')));
      } catch (_) {
        await secrets.delete(existing.secretRef!);
        rethrow;
      }
    }
    await (database.update(
      database.backupStatusRows,
    )..where((t) => t.walletId.equals(entry.walletId))).write(
      BackupStatusRowsCompanion(
        state: const Value('verified'),
        lastVerifiedAt: Value(entry.createdAt ?? entry.file.modifiedAt),
        scope: Value(_cloudScope),
      ),
    );
  }

  Future<void> deleteLocal(String walletId) async {
    final row = await _wallet(walletId);
    if (row == null) return;
    await (database.update(database.walletRows)
          ..where((t) => t.id.equals(walletId)))
        .write(const WalletRowsCompanion(state: Value('deleting')));
    await _finishDeletion(row);
  }

  Future<void> _finishDeletion(WalletRow row) async {
    if (row.secretRef != null) await secrets.delete(row.secretRef!);
    await (database.delete(
      database.walletRows,
    )..where((t) => t.id.equals(row.id))).go();
  }

  Future<WalletRow?> _wallet(String id) => (database.select(
    database.walletRows,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> _insertWallet({
    required String id,
    required WalletKind kind,
    required String name,
    String? secretRef,
  }) async {
    final now = DateTime.now().toUtc();
    await database
        .into(database.walletRows)
        .insert(
          WalletRowsCompanion.insert(
            id: id,
            kind: kind.databaseValue,
            name: name,
            secretRef: Value(secretRef),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.backupStatusRows)
        .insert(BackupStatusRowsCompanion.insert(walletId: id));
  }

  Future<void> _insertAccountAddress(
    String walletId,
    WalletChain chain,
    String address, {
    String path = '',
    int? index,
  }) async {
    final accountId = _id();
    await database
        .into(database.accountRows)
        .insert(
          AccountRowsCompanion.insert(
            id: accountId,
            walletId: walletId,
            chainFamily: chain.family,
            coinType: chain.coinType.value,
            addressFormat: chain.addressFormat,
            derivationProfile: 'wallet-core-4.8.1-default',
            createdAt: DateTime.now().toUtc(),
          ),
        );
    await database
        .into(database.addressRows)
        .insert(
          AddressRowsCompanion.insert(
            id: _id(),
            accountId: accountId,
            derivationPath: Value(path),
            changeIndex: index == null ? const Value.absent() : const Value(0),
            addressIndex: Value(index),
            address: address,
            addressNormalized: _normalizeAddress(chain, address),
            isPrimary: const Value(true),
          ),
        );
    for (final (networkId, label) in chain.networks) {
      await database
          .into(database.networkRows)
          .insertOnConflictUpdate(
            NetworkRowsCompanion.insert(
              id: networkId,
              chainFamily: chain.family,
              displayName: label,
            ),
          );
      await database
          .into(database.accountNetworkRows)
          .insert(
            AccountNetworkRowsCompanion.insert(
              accountId: accountId,
              networkId: networkId,
            ),
          );
    }
  }

  static String _normalizeAddress(WalletChain chain, String address) =>
      chain == WalletChain.evm ? address.toLowerCase() : address;

  static String _name(String value) {
    final clean = value.trim();
    if (clean.isEmpty ||
        clean.runes.length > 64 ||
        clean.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
      throw const FormatException('Wallet name must have 1–64 characters.');
    }
    return clean;
  }

  static Uint8List _decodeKey(String hex) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hex)) {
      throw const FormatException(
        'Private key must contain exactly 32 bytes of hex.',
      );
    }
    return Uint8List.fromList(<int>[
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
  }
}
