import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/src/crypto/mnemonic_sealer.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

import '../support/fake_wallet_core.dart';

const _cheap = BackupKdfParameters(memoryKiB: 64, iterations: 1, parallelism: 1);
const _password = 'correct horse battery';

void main() {
  group('MnemonicSealer', () {
    late MnemonicSealer sealer;

    setUp(() => sealer = MnemonicSealer(kdf: _cheap, minimumKdf: _cheap, random: Random(1)));

    Future<WalletBackup> seal({String walletId = 'wallet-1', String? label, String? mnemonic}) =>
        sealer.seal(
          walletId: walletId,
          mnemonic: mnemonic ?? mnemonic12,
          ethereumAddress: '0xabc',
          password: _password,
          label: label,
        );

    /// Rewrites the stored fields and recomputes the checksum, as an attacker
    /// with write access to the cloud file could.
    Future<WalletBackup> tamper(
      WalletBackup backup,
      void Function(Map<String, Object?> fields) edit, {
      String? walletId,
    }) {
      final fields = jsonDecode(jsonEncode(backup.encryptedKeystore)) as Map<String, Object?>;
      edit(fields);
      return WalletBackup.create(
        walletId: walletId ?? backup.walletId,
        encryptedKeystore: fields,
        createdAt: backup.createdAt,
      );
    }

    String flipFirstByte(Object? base64Value) {
      final bytes = base64Decode(base64Value! as String);
      bytes[0] ^= 1;
      return base64Encode(bytes);
    }

    test('round-trips the mnemonic and address', () async {
      final backup = await seal(label: 'Main');
      final contents = await sealer.open(backup, password: _password);

      expect(contents.mnemonic, mnemonic12);
      expect(contents.ethereumAddress, '0xabc');
      expect(sealer.inspect(backup)!.label, 'Main');
    });

    test('keeps the mnemonic and address out of the stored JSON', () async {
      final json = (await seal()).encode();

      expect(json, isNot(contains('abandon')));
      expect(json, isNot(contains('0xabc')));
      expect(json, isNot(contains(_password)));
    });

    test('reports a wrong password', () async {
      await expectLater(
        sealer.open(await seal(), password: 'wrong password'),
        throwsA(isA<WrongBackupPasswordException>()),
      );
    });

    test('pads the plaintext so 12 and 24 words look the same', () async {
      final short = await seal();
      final long = await seal(mnemonic: mnemonic24);

      expect(
        short.encryptedKeystore['cipherText'].toString().length,
        long.encryptedKeystore['cipherText'].toString().length,
      );
    });

    test('uses a fresh salt and nonce for every backup', () async {
      final first = await seal();
      final second = await seal();

      expect(
        first.encryptedKeystore['keyDerivation'],
        isNot(second.encryptedKeystore['keyDerivation']),
      );
      expect(first.encryptedKeystore['nonce'], isNot(second.encryptedKeystore['nonce']));
    });

    group('rejects a rewritten file', () {
      test('ciphertext → integrity', () async {
        final forged = await tamper(
          await seal(),
          (f) => f['cipherText'] = flipFirstByte(f['cipherText']),
        );

        await expectLater(
          sealer.open(forged, password: _password),
          throwsA(isA<BackupIntegrityException>()),
        );
      });

      test('label → integrity', () async {
        final forged = await tamper(await seal(label: 'Main'), (f) => f['label'] = 'Savings');

        await expectLater(
          sealer.open(forged, password: _password),
          throwsA(isA<BackupIntegrityException>()),
        );
      });

      // The header is authenticated by blacklist: everything except nonce,
      // cipherText and mac goes into the AAD, so fields nobody knows about are
      // covered too. Turning that into a whitelist would silently stop
      // authenticating injected fields, and nothing else here would notice.
      test('injected unknown field → integrity', () async {
        final forged = await tamper(await seal(), (f) => f['injected'] = 'evil');

        await expectLater(
          sealer.open(forged, password: _password),
          throwsA(isA<BackupIntegrityException>()),
        );
      });

      test('moved to another wallet → integrity', () async {
        final forged = await tamper(await seal(), (_) {}, walletId: 'wallet-2');

        await expectLater(
          sealer.open(forged, password: _password),
          throwsA(isA<BackupIntegrityException>()),
        );
      });

      test('salt or key check → wrong password', () async {
        final backup = await seal();
        final salted = await tamper(backup, (f) {
          final derivation = f['keyDerivation']! as Map<String, Object?>;
          derivation['salt'] = flipFirstByte(derivation['salt']);
        });
        final checked = await tamper(backup, (f) => f['keyCheck'] = flipFirstByte(f['keyCheck']));

        await expectLater(
          sealer.open(salted, password: _password),
          throwsA(isA<WrongBackupPasswordException>()),
        );
        await expectLater(
          sealer.open(checked, password: _password),
          throwsA(isA<WrongBackupPasswordException>()),
        );
      });

      test('iterations → wrong password', () async {
        final forged = await tamper(await seal(), (f) {
          (f['keyDerivation']! as Map<String, Object?>)['iterations'] = 2;
        });

        await expectLater(
          sealer.open(forged, password: _password),
          throwsA(isA<WrongBackupPasswordException>()),
        );
      });

      test('creation time → integrity', () async {
        final backup = await seal();
        final forged = await WalletBackup.create(
          walletId: backup.walletId,
          encryptedKeystore: backup.encryptedKeystore,
          createdAt: backup.createdAt.add(const Duration(days: 1)),
        );

        await expectLater(
          sealer.open(forged, password: _password),
          throwsA(isA<BackupIntegrityException>()),
        );
      });

      test('Argon2id cost above the cap → format error before deriving', () async {
        final forged = await tamper(await seal(), (f) {
          final derivation = f['keyDerivation']! as Map<String, Object?>;
          derivation['memoryKiB'] = 262144;
          derivation['iterations'] = 10;
        });

        expect(() => sealer.inspect(forged), throwsA(isA<BackupFormatException>()));
      });

      test('memory-exhausting KDF parameters → format error before deriving', () async {
        final forged = await tamper(await seal(), (f) {
          (f['keyDerivation']! as Map<String, Object?>)['memoryKiB'] = 4 * 1024 * 1024;
        });

        expect(() => sealer.inspect(forged), throwsA(isA<BackupFormatException>()));
      });

      test('nonce of the wrong length → format error', () async {
        final forged = await tamper(await seal(), (f) => f['nonce'] = base64Encode(<int>[1, 2, 3]));

        expect(() => sealer.inspect(forged), throwsA(isA<BackupFormatException>()));
      });
    });

    test('rejects KDF parameters below the minimum when reading', () async {
      final strict = MnemonicSealer(kdf: BackupKdfParameters.minimum);
      final weak = await seal();

      expect(() => strict.inspect(weak), throwsA(isA<BackupFormatException>()));
    });

    test('does not recognize other backups', () async {
      final other = await WalletBackup.create(
        walletId: 'wallet-1',
        encryptedKeystore: <String, Object?>{'version': 3, 'crypto': <String, Object?>{}},
      );

      expect(sealer.inspect(other), isNull);
      await expectLater(
        sealer.open(other, password: _password),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('validates labels', () {
      expect(MnemonicSealer.normalizeLabel('  Main  '), 'Main');
      expect(MnemonicSealer.normalizeLabel('   '), isNull);
      expect(() => MnemonicSealer.normalizeLabel('a\nb'), throwsA(isA<BackupFormatException>()));
      expect(() => MnemonicSealer.normalizeLabel('x' * 65), throwsA(isA<BackupFormatException>()));
    });

    test('redacts decrypted contents in toString', () async {
      final contents = await sealer.open(await seal(), password: _password);

      expect(contents.toString(), isNot(contains('abandon')));
    });

    test('refuses weak KDF parameters for new backups', () {
      expect(() => MnemonicSealer(kdf: _cheap), throwsArgumentError);
    });

    test('still opens the frozen v1 format', () async {
      final backup = await WalletBackup.decodeAndVerify(_goldenV1);

      final contents = await sealer.open(backup, password: 'golden password');

      expect(contents.mnemonic, mnemonic12);
      expect(contents.ethereumAddress, '0x9858EfFD232B4033E47d90003D41EC34EcaEda94');
      expect(sealer.inspect(backup)!.label, 'Golden');
    });

    test('works with the recommended Argon2id parameters', () async {
      final production = MnemonicSealer();
      final backup = await production.seal(
        walletId: 'wallet-1',
        mnemonic: mnemonic12,
        ethereumAddress: '0xabc',
        password: _password,
      );

      expect((await production.open(backup, password: _password)).mnemonic, mnemonic12);
      expect(production.inspect(backup)!.kdf, BackupKdfParameters.recommended);
    });
  });
}

// Sealed once with the v1 scheme (cheap test parameters). Must keep opening.
const _goldenV1 =
    '{"formatVersion":1,"walletId":"golden-wallet","encryptedKeystore":{"scheme":'
    '"wallet_cloud_backup.mnemonic.v1","label":"Golden","keyCheck":"Za4CLPFkRq9n3TWccNecAw==",'
    '"keyDerivation":{"algorithm":"argon2id","version":19,"memoryKiB":64,"iterations":1,'
    '"parallelism":1,"salt":"M67EXbVojz0wuP/kM3NNGg=="},"algorithm":"AES-256-GCM",'
    '"nonce":"rCWoI7FP0e0UYlZb","cipherText":"v9oGCpkHCYONZaRlLxZGdagFoncVle0pnF+XuCTyxNJaZsEU3'
    'nJ1c5UMGRnmQXj78+iccFFlF3uWYrq3xlKqh9o7HzdX4gWkiD7GdjpDHip3r8gbG3hE2TaQpHbQBuPa7ZzqnZEqhKK'
    'HSYj2AnRX9KDls73AJWBqSquoIAsVI/9+pvypPM1/3iyPCYEjCY+KmRJN+gXgEXkPAhVdWX6kGRqmJpzXZjzEyV+LF'
    '/p6Ecbxaj7/WtiecLMVS2fYXDvnXi60yU6HcmMyR+gHTnV1WeLGJLteV1RQrZDY2BjitNlw00e4DULbCBwKjAKjkQq'
    'nXcBY4sJAYDvA4lDBlNpMFy7pzmlYqF0O5roY1qFQj93pkbvP1+SV2Kz4/XRf9C3pDSIPdiitMTZUpftwkAmmj+cAa'
    '05LTjpxeZrcNdbCJVV4TcmhEKHDVAIW6bUH6NI0QcGWBspsYedIXqaaErhpmma1/FLp+KP7+yxwZRMgjCQ/49MW4X6'
    'V3nKesoI3dvbEdA9fXeKITin73MUpZoZKSTDRK0lp+3iqb0SuY9OYUOiHyOESGAw6rMXb9n+4Ka+LxhRLDPihwQdU3'
    'SdDyzRchEv7rJP1p+OrPrWaFJ+N/p/LAg3OqB4lheq29qyoy2mjgenhXWo7eeJzh0Teb8FxKFVhx5kcaxHJQ2BJkLY'
    'YnR8=","mac":"JZNMPae0XFAIK625ea/cPA=="},"createdAt":"2026-09-22T08:00:00.000Z",'
    '"checksum":"9007c590ab18beeffd7767d74f22550939661ef16c8f24fbc984391e0d7ea918"}';
