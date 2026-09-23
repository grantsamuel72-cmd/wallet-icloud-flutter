import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Argon2id (RFC 9106, version 0x13) cost parameters, stored with each backup
/// so they can be raised later without breaking older backups.
class BackupKdfParameters {
  /// Creates Argon2id parameters.
  const BackupKdfParameters({this.memoryKiB = 65536, this.iterations = 3, this.parallelism = 4});

  /// RFC 9106's second recommended option: 64 MiB, 3 passes, 4 lanes.
  static const BackupKdfParameters recommended = BackupKdfParameters();

  /// Weakest parameters accepted anywhere (OWASP's Argon2id minimum).
  static const BackupKdfParameters minimum = BackupKdfParameters(
    memoryKiB: 19456,
    iterations: 2,
    parallelism: 1,
  );

  /// Upper bound per parameter accepted when reading. Together with
  /// [maximumCost] this bounds the memory and time a crafted file can demand.
  static const BackupKdfParameters maximum = BackupKdfParameters(
    memoryKiB: 262144,
    iterations: 10,
    parallelism: 8,
  );

  /// Upper bound for [memoryKiB] × [iterations]: four times [recommended],
  /// about 1.3 s on an M-series Mac and a few seconds on a phone.
  static const int maximumCost = 4 * 65536 * 3;

  /// Memory cost in KiB.
  final int memoryKiB;

  /// Number of passes over memory.
  final int iterations;

  /// Number of lanes.
  final int parallelism;

  /// Whether every parameter lies between [lower] and [upper], inclusive, and
  /// the total cost is at most [maximumCost].
  bool isWithin(BackupKdfParameters lower, BackupKdfParameters upper) =>
      memoryKiB * iterations <= maximumCost &&
      memoryKiB >= lower.memoryKiB &&
      memoryKiB <= upper.memoryKiB &&
      iterations >= lower.iterations &&
      iterations <= upper.iterations &&
      parallelism >= lower.parallelism &&
      parallelism <= upper.parallelism &&
      memoryKiB >= 8 * parallelism;

  @override
  bool operator ==(Object other) =>
      other is BackupKdfParameters &&
      memoryKiB == other.memoryKiB &&
      iterations == other.iterations &&
      parallelism == other.parallelism;

  @override
  int get hashCode => Object.hash(memoryKiB, iterations, parallelism);

  @override
  String toString() =>
      'BackupKdfParameters(memoryKiB: $memoryKiB, iterations: $iterations, '
      'parallelism: $parallelism)';
}

/// Derives a 32-byte Argon2id key from [password] and [salt].
///
/// Runs on a background isolate so the UI keeps rendering during the
/// deliberately slow derivation.
Future<Uint8List> deriveArgon2idKey(
  Uint8List password,
  Uint8List salt,
  BackupKdfParameters parameters,
) {
  final memoryKiB = parameters.memoryKiB;
  final iterations = parameters.iterations;
  final parallelism = parameters.parallelism;
  return Isolate.run(() async {
    // Sending [password] copies it into this isolate, so the caller's own
    // wipe does not reach this copy. Clearing it is best effort: a managed
    // runtime still leaves copies the Dart code never sees.
    try {
      final key = await DartArgon2id(
        parallelism: parallelism,
        memory: memoryKiB,
        iterations: iterations,
        hashLength: 32,
      ).deriveKey(secretKey: SecretKeyData(password), nonce: salt);
      return Uint8List.fromList(await key.extractBytes());
    } finally {
      password.fillRange(0, password.length, 0);
    }
  });
}
