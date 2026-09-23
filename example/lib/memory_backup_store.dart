import 'dart:typed_data';

import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

/// Keeps backups in memory so the demo runs without iCloud or Google Drive.
class MemoryBackupStore implements CloudBackupStore {
  final Map<String, Uint8List> _files = <String, Uint8List>{};
  final Map<String, DateTime> _modified = <String, DateTime>{};

  @override
  CloudBackupProvider get provider => CloudBackupProvider.iCloud;

  @override
  Future<bool> connect({bool interactive = false}) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<CloudBackupFile> write(String fileName, Uint8List contents) async {
    _files[fileName] = Uint8List.fromList(contents);
    _modified[fileName] = DateTime.now().toUtc();
    return _file(fileName);
  }

  @override
  Future<Uint8List> read(String fileName) async {
    final contents = _files[fileName];
    if (contents == null) {
      throw BackupNotFoundException(fileName);
    }
    return Uint8List.fromList(contents);
  }

  @override
  Future<List<CloudBackupFile>> list() async {
    final names = _files.keys.toList()
      ..sort((left, right) => _modified[right]!.compareTo(_modified[left]!));
    return names.map(_file).toList(growable: false);
  }

  @override
  Future<void> delete(String fileName) async {
    if (_files.remove(fileName) == null) {
      throw BackupNotFoundException(fileName);
    }
    _modified.remove(fileName);
  }

  CloudBackupFile _file(String fileName) => CloudBackupFile(
    id: fileName,
    name: fileName,
    provider: provider,
    modifiedAt: _modified[fileName],
    sizeInBytes: _files[fileName]!.length,
  );
}
