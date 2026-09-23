import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  group('WalletBackup', () {
    final createdAt = DateTime.utc(2026, 9, 22, 8);

    test('round-trips and verifies an encrypted keystore', () async {
      final backup = await WalletBackup.create(
        walletId: 'wallet-1',
        encryptedKeystore: <String, Object?>{
          'version': 3,
          'crypto': <String, Object?>{'cipher': 'aes-128-ctr', 'ciphertext': 'deadbeef'},
        },
        createdAt: createdAt,
      );

      final restored = await WalletBackup.decodeAndVerify(backup.encode());

      expect(restored.formatVersion, WalletBackup.currentFormatVersion);
      expect(restored.walletId, 'wallet-1');
      expect(restored.createdAt, createdAt);
      expect(restored.encryptedKeystore['version'], 3);
      expect(restored.checksum, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('canonical checksum is independent of map insertion order', () async {
      final first = await WalletBackup.create(
        walletId: 'wallet-1',
        encryptedKeystore: <String, Object?>{'a': 1, 'b': 2},
        createdAt: createdAt,
      );
      final second = await WalletBackup.create(
        walletId: 'wallet-1',
        encryptedKeystore: <String, Object?>{'b': 2, 'a': 1},
        createdAt: createdAt,
      );

      expect(first.checksum, second.checksum);
    });

    test('rejects modified backup content', () async {
      final backup = await WalletBackup.create(
        walletId: 'wallet-1',
        encryptedKeystore: <String, Object?>{'ciphertext': 'safe'},
        createdAt: createdAt,
      );
      final decoded = Map<String, Object?>.from(
        jsonDecode(backup.encode()) as Map<String, Object?>,
      );
      decoded['walletId'] = 'attacker-wallet';

      await expectLater(
        WalletBackup.decodeAndVerify(jsonEncode(decoded)),
        throwsA(isA<BackupIntegrityException>()),
      );
    });

    test('rejects an untrimmed walletId in a stored document', () async {
      final backup = await WalletBackup.create(
        walletId: 'wallet-1',
        encryptedKeystore: <String, Object?>{'ciphertext': 'safe'},
        createdAt: createdAt,
      );
      final decoded = jsonDecode(backup.encode()) as Map<String, Object?>;
      decoded['walletId'] = ' wallet-1';

      await expectLater(
        WalletBackup.decodeAndVerify(jsonEncode(decoded)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('keeps the checksum algorithm stable', () async {
      final backup = await WalletBackup.create(
        walletId: 'wallet-1',
        encryptedKeystore: <String, Object?>{
          'b': <Object?>[1, 'x', null],
          'a': true,
        },
        createdAt: createdAt,
      );

      expect(backup.checksum, 'fc18a20ddf6a4ea0526d95ec6a7a8f19c1aca4ed1f47658ac44521e65de68093');
    });

    test('rejects deeply nested content instead of overflowing the stack', () async {
      final nested = '${'[' * 100000}${']' * 100000}';
      final document =
          '{"formatVersion":1,"walletId":"w","encryptedKeystore":{"x":$nested},'
          '"createdAt":"2026-09-22T08:00:00.000Z","checksum":"${'0' * 64}"}';

      await expectLater(
        WalletBackup.decodeAndVerify(document),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects an empty keystore', () async {
      await expectLater(
        WalletBackup.create(walletId: 'wallet-1', encryptedKeystore: <String, Object?>{}),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
