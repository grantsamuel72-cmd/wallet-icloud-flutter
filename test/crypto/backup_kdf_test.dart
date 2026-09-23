import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/src/crypto/backup_kdf.dart';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

String _hex(List<int> bytes) => bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('BackupKdfParameters', () {
    const minimum = BackupKdfParameters.minimum;
    const maximum = BackupKdfParameters.maximum;

    test('accepts the recommended and boundary parameters', () {
      expect(BackupKdfParameters.recommended.isWithin(minimum, maximum), isTrue);
      expect(minimum.isWithin(minimum, maximum), isTrue);
      expect(
        const BackupKdfParameters(
          memoryKiB: 262144,
          iterations: 3,
          parallelism: 8,
        ).isWithin(minimum, maximum),
        isTrue,
      );
    });

    test('rejects each parameter outside its range', () {
      for (final parameters in <BackupKdfParameters>[
        const BackupKdfParameters(memoryKiB: 19455, iterations: 2, parallelism: 1),
        const BackupKdfParameters(memoryKiB: 262145, iterations: 2, parallelism: 1),
        const BackupKdfParameters(memoryKiB: 65536, iterations: 1, parallelism: 1),
        const BackupKdfParameters(memoryKiB: 65536, iterations: 11, parallelism: 1),
        const BackupKdfParameters(memoryKiB: 65536, iterations: 3, parallelism: 0),
        const BackupKdfParameters(memoryKiB: 65536, iterations: 3, parallelism: 9),
      ]) {
        expect(parameters.isWithin(minimum, maximum), isFalse, reason: '$parameters');
      }
    });

    test('caps memory × iterations at four times the recommended cost', () {
      const atCap = BackupKdfParameters(memoryKiB: 196608, iterations: 4, parallelism: 1);
      const overCap = BackupKdfParameters(memoryKiB: 262144, iterations: 4, parallelism: 1);

      expect(atCap.memoryKiB * atCap.iterations, BackupKdfParameters.maximumCost);
      expect(atCap.isWithin(minimum, maximum), isTrue);
      expect(overCap.isWithin(minimum, maximum), isFalse);
    });

    test('needs at least 8 KiB per lane', () {
      const lower = BackupKdfParameters(memoryKiB: 8, iterations: 1, parallelism: 1);

      expect(
        const BackupKdfParameters(
          memoryKiB: 16,
          iterations: 1,
          parallelism: 2,
        ).isWithin(lower, maximum),
        isTrue,
      );
      expect(
        const BackupKdfParameters(
          memoryKiB: 15,
          iterations: 1,
          parallelism: 2,
        ).isWithin(lower, maximum),
        isFalse,
      );
    });

    test('compares by value', () {
      expect(
        const BackupKdfParameters(memoryKiB: 65536, iterations: 3, parallelism: 4),
        BackupKdfParameters.recommended,
      );
      expect(
        const BackupKdfParameters(memoryKiB: 65536, iterations: 3, parallelism: 4).hashCode,
        BackupKdfParameters.recommended.hashCode,
      );
      expect(BackupKdfParameters.recommended, isNot(BackupKdfParameters.minimum));
      expect(BackupKdfParameters.recommended.toString(), contains('memoryKiB: 65536'));
    });
  });

  group('deriveArgon2idKey', () {
    const passwordText = 'correct horse battery';
    // Rebuilt per test: sharing one mutable buffer would let an earlier test's
    // mutation hide a leak in a later one.
    Uint8List password() => _bytes(passwordText);
    Uint8List salt() => _bytes('0123456789abcdef');

    // Expected values come from Node.js crypto.argon2Sync('argon2id', ...), an
    // independent implementation, so they also pin the KiB unit and argument order.
    test('matches an independent implementation', () async {
      final single = await deriveArgon2idKey(
        password(),
        salt(),
        const BackupKdfParameters(memoryKiB: 64, iterations: 1, parallelism: 1),
      );
      final multiLane = await deriveArgon2idKey(
        password(),
        salt(),
        const BackupKdfParameters(memoryKiB: 256, iterations: 2, parallelism: 2),
      );

      expect(_hex(single), 'feeaf97cb10b51bd5e5e44fda0a1eaaba807199f4f87081b8f8ab221c08d6987');
      expect(_hex(multiLane), '52630c03d78a6897ae8dded993d5677d0c2e324c910f65cffe066d664907e2a7');
    });

    test('returns 32 bytes that depend on password and salt', () async {
      const cheap = BackupKdfParameters(memoryKiB: 64, iterations: 1, parallelism: 1);
      final base = await deriveArgon2idKey(password(), salt(), cheap);

      expect(base, hasLength(32));
      expect(await deriveArgon2idKey(password(), salt(), cheap), base);
      expect(await deriveArgon2idKey(_bytes('other password'), salt(), cheap), isNot(base));
      expect(await deriveArgon2idKey(password(), _bytes('fedcba9876543210'), cheap), isNot(base));
    });

    // Guards the wipe inside the derivation isolate: it must reach only that
    // isolate's own copy. Compared against a literal, because comparing two
    // buffers that would both be wiped proves nothing.
    test('leaves the caller buffers untouched', () async {
      final passwordCopy = _bytes(passwordText);

      await deriveArgon2idKey(
        passwordCopy,
        salt(),
        const BackupKdfParameters(memoryKiB: 64, iterations: 1, parallelism: 1),
      );

      expect(utf8.decode(passwordCopy), passwordText);
    });
  });
}
