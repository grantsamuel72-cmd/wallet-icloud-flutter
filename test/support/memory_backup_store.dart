import 'dart:typed_data';

import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

/// In-memory [CloudBackupStore] for tests.
class MemoryBackupStore implements CloudBackupStore {
  final Map<String, Uint8List> files = <String, Uint8List>{};

  /// Number of successful writes.
  int writes = 0;

  /// Replaces what [read] returns, e.g. to simulate a provider serving stale data.
  Uint8List Function(String fileName, Uint8List stored)? onRead;

  /// Makes [read] take time, so overlapping reads are observable.
  Duration readDelay = Duration.zero;

  /// Highest number of [read] calls that were in flight at the same time.
  int peakConcurrentReads = 0;

  int _concurrentReads = 0;

  @override
  CloudBackupProvider get provider => CloudBackupProvider.googleDrive;

  @override
  Future<bool> connect({bool interactive = false}) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> delete(String fileName) async {
    if (files.remove(fileName) == null) {
      throw BackupNotFoundException(fileName);
    }
  }

  @override
  Future<List<CloudBackupFile>> list() async => <CloudBackupFile>[
    for (final entry in files.entries)
      CloudBackupFile(
        id: entry.key,
        name: entry.key,
        provider: provider,
        sizeInBytes: entry.value.length,
      ),
  ];

  @override
  Future<Uint8List> read(String fileName) async {
    _concurrentReads += 1;
    peakConcurrentReads = peakConcurrentReads < _concurrentReads
        ? _concurrentReads
        : peakConcurrentReads;
    try {
      if (readDelay > Duration.zero) {
        await Future<void>.delayed(readDelay);
      }
      final value = files[fileName];
      if (value == null) {
        throw BackupNotFoundException(fileName);
      }
      final copy = Uint8List.fromList(value);
      return onRead?.call(fileName, copy) ?? copy;
    } finally {
      _concurrentReads -= 1;
    }
  }

  @override
  Future<CloudBackupFile> write(String fileName, Uint8List contents) async {
    files[fileName] = Uint8List.fromList(contents);
    writes += 1;
    return CloudBackupFile(
      id: fileName,
      name: fileName,
      provider: provider,
      sizeInBytes: contents.length,
    );
  }
}
