import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  group('AesGcmBackupCipher', () {
    const keyDerivation = <String, Object?>{'algorithm': 'argon2id', 'salt': 'c2FsdA=='};

    test('round-trips bytes and key-derivation parameters through JSON', () async {
      final cipher = AesGcmBackupCipher();
      final key = SecretKeyData(List<int>.generate(32, (index) => index));
      final clearText = Uint8List.fromList(utf8.encode('{"encrypted":"keystore"}'));

      final encrypted = await cipher.encrypt(clearText, key: key, keyDerivation: keyDerivation);
      final serialized = AesGcmEncryptedPayload.fromJson(
        jsonDecode(jsonEncode(encrypted.toJson())) as Map<String, Object?>,
      );
      final decrypted = await cipher.decrypt(serialized, key: key);

      expect(decrypted, clearText);
      expect(encrypted.nonce, hasLength(12));
      expect(encrypted.mac, hasLength(16));
      expect(serialized.keyDerivation, keyDerivation);
    });

    test('rejects a wrong key', () async {
      final cipher = AesGcmBackupCipher();
      final encrypted = await cipher.encrypt(
        Uint8List.fromList(<int>[1, 2, 3]),
        key: SecretKeyData(List<int>.filled(32, 1)),
        keyDerivation: keyDerivation,
      );

      await expectLater(
        cipher.decrypt(encrypted, key: SecretKeyData(List<int>.filled(32, 2))),
        throwsA(isA<BackupIntegrityException>()),
      );
    });

    test('requires an exact 256-bit key', () async {
      final cipher = AesGcmBackupCipher();

      await expectLater(
        cipher.encrypt(
          Uint8List(0),
          key: SecretKeyData(List<int>.filled(16, 1)),
          keyDerivation: keyDerivation,
        ),
        throwsArgumentError,
      );
    });

    test('authenticates associated data', () async {
      final cipher = AesGcmBackupCipher();
      final key = SecretKeyData(List<int>.filled(32, 3));
      final encrypted = await cipher.encrypt(
        Uint8List.fromList(<int>[1, 2, 3]),
        key: key,
        keyDerivation: keyDerivation,
        aad: utf8.encode('wallet-1'),
      );

      expect(await cipher.decrypt(encrypted, key: key, aad: utf8.encode('wallet-1')), <int>[
        1,
        2,
        3,
      ]);
      await expectLater(
        cipher.decrypt(encrypted, key: key, aad: utf8.encode('wallet-2')),
        throwsA(isA<BackupIntegrityException>()),
      );
    });

    test('requires key-derivation parameters', () async {
      final cipher = AesGcmBackupCipher();
      final key = SecretKeyData(List<int>.filled(32, 1));

      await expectLater(
        cipher.encrypt(Uint8List(0), key: key, keyDerivation: const <String, Object?>{}),
        throwsArgumentError,
      );

      final json = (await cipher.encrypt(
        Uint8List(1),
        key: key,
        keyDerivation: keyDerivation,
      )).toJson()..remove('keyDerivation');
      expect(() => AesGcmEncryptedPayload.fromJson(json), throwsA(isA<BackupFormatException>()));
    });
  });
}
