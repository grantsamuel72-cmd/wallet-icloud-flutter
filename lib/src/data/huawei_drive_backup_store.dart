import 'dart:io';

import 'package:flutter/services.dart';
import 'package:huawei_drive/huawei_drive.dart' as huawei;
import 'package:path/path.dart' as p;
import 'package:wallet_cloud_backup/src/domain/backup_file_names.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_file.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_store.dart';
import 'package:wallet_cloud_backup/src/domain/exceptions.dart';

/// Supplies Huawei ID credentials with the `drive.appdata` scope.
///
/// Return null when silent sign-in is unavailable or the user cancels an
/// interactive sign-in. The host app owns the Huawei Account Kit session.
typedef HuaweiDriveCredentialsProvider =
    Future<huawei.DriveCredentials?> Function({required bool interactive});

/// Stores encrypted backups in Huawei Drive's hidden `applicationData` space.
///
/// The host app must configure AppGallery Connect and supply credentials from
/// Huawei Account Kit. This backend is opt-in; Android continues to use Google
/// Drive in the default [WalletCloudBackup] constructor.
class HuaweiDriveBackupStore implements CloudBackupStore {
  /// Creates a Huawei Drive backend.
  HuaweiDriveBackupStore({
    required this.credentialsProvider,
    this.maxObjectSizeInBytes = defaultMaxBackupSizeInBytes,
  }) {
    if (maxObjectSizeInBytes <= 0) {
      throw ArgumentError.value(maxObjectSizeInBytes, 'maxObjectSizeInBytes', 'Must be positive.');
    }
  }

  static const String _space = 'applicationData';
  static const String _mimeType = 'application/json';
  static const String _fields =
      'nextCursor,files(id,fileName,size,createdTime,editedTime,recycled)';

  final HuaweiDriveCredentialsProvider credentialsProvider;
  huawei.Drive? _drive;
  String? _unionId;
  String? _boundUnionId;

  /// Pins the account for one visible backup operation or list. A changed
  /// HUAWEI ID must be explicitly selected before its records are accessible.
  void bindAccount(String? unionId) => _boundUnionId = unionId;

  /// Account of the current Drive client, if connected.
  String? get accountId => _unionId;

  /// Maximum object size loaded into memory.
  final int maxObjectSizeInBytes;

  @override
  CloudBackupProvider get provider => CloudBackupProvider.huaweiDrive;

  @override
  Future<bool> connect({bool interactive = false}) async {
    final huawei.DriveCredentials? credentials;
    try {
      credentials = await credentialsProvider(interactive: interactive);
      if (credentials == null) {
        _drive = null;
        _unionId = null;
        return false;
      }
      if (credentials.unionId == null || credentials.unionId!.isEmpty) {
        throw const CloudAuthenticationException('Huawei Drive account ID is missing.');
      }
      if (_boundUnionId != null && credentials.unionId != _boundUnionId) {
        _drive = null;
        _unionId = null;
        throw const CloudAuthenticationException('华为账号已切换，请重新查询当前账号的云备份。');
      }
      if (_drive != null && _unionId == credentials.unionId) return true;
      _drive = null;
      _drive = await huawei.Drive.init(credentials);
      _unionId = credentials.unionId;
      return true;
    } on WalletCloudBackupException {
      rethrow;
    } on MissingPluginException catch (error) {
      throw CloudUnavailableException('Huawei Drive is unavailable on this device.', cause: error);
    } on PlatformException catch (error) {
      throw CloudAuthenticationException(
        'Huawei Drive sign-in failed: ${error.message ?? error.code}',
        cause: error,
      );
    } on Exception catch (error) {
      throw CloudAuthenticationException('Huawei Drive sign-in failed.', cause: error);
    }
  }

  @override
  Future<void> disconnect() async {
    // Huawei Account Kit owns sign-out; discard only this store's Drive session.
    _drive = null;
    _unionId = null;
  }

  @override
  Future<CloudBackupFile> write(String fileName, Uint8List contents) async {
    assertPlainBackupFileName(fileName);
    _validateSize(contents.length);
    return _withDrive((drive) async {
      final matches = await _matchingFiles(drive, fileName);
      final directory = await Directory.systemTemp.createTemp('wallet-cloud-backup-');
      try {
        final source = File(p.join(directory.path, 'backup.json'));
        await source.writeAsBytes(contents, flush: true);
        final content = huawei.DriveFileContent(type: _mimeType, path: source.path);
        final huawei.DriveFile stored;
        if (matches.isEmpty) {
          stored = await drive.files.create(
            huawei.FilesRequest.create(
              huawei.DriveFile(
                fileName: fileName,
                mimeType: _mimeType,
                parentFolder: const <String>[_space],
              ),
              fileContent: content,
            ),
          );
        } else {
          stored = await drive.files.update(
            huawei.FilesRequest.update(
              matches.first.id,
              huawei.DriveFile(fileName: fileName, mimeType: _mimeType),
              fileContent: content,
            ),
          );
          for (final duplicate in matches.skip(1)) {
            try {
              await drive.files.delete(huawei.FilesRequest.delete(duplicate.id));
            } on PlatformException {
              // The updated backup already exists; stale-copy cleanup is best effort.
            }
          }
        }
        return _file(stored, fallbackName: fileName);
      } finally {
        await directory.delete(recursive: true);
      }
    });
  }

  @override
  Future<Uint8List> read(String fileName) async {
    assertPlainBackupFileName(fileName);
    return _withDrive((drive) async {
      final matches = await _matchingFiles(drive, fileName);
      if (matches.isEmpty) throw BackupNotFoundException(fileName);
      final bytes = await drive.files.getContentAsInputStream(
        huawei.FilesRequest.getRequest(matches.first.id),
      );
      _validateSize(bytes.length);
      return Uint8List.fromList(bytes);
    });
  }

  @override
  Future<List<CloudBackupFile>> list() => _withDrive((drive) async {
    final files = (await _allFiles(drive)).map(_file).toList()..sort(compareBackupsNewestFirst);
    return List<CloudBackupFile>.unmodifiable(files);
  });

  @override
  Future<void> delete(String fileName) async {
    assertPlainBackupFileName(fileName);
    await _withDrive((drive) async {
      final matches = await _matchingFiles(drive, fileName);
      if (matches.isEmpty) throw BackupNotFoundException(fileName);
      for (final file in matches) {
        await drive.files.delete(huawei.FilesRequest.delete(file.id));
      }
    });
  }

  Future<T> _withDrive<T>(Future<T> Function(huawei.Drive drive) action) async {
    // Refresh identity before every operation so a switched HUAWEI ID cannot
    // read or mutate data through a cached Drive client from the old account.
    if (!await connect()) {
      throw const CloudAuthenticationException('Huawei Drive authorization is required.');
    }
    try {
      return await action(_drive!);
    } on WalletCloudBackupException {
      rethrow;
    } on MissingPluginException catch (error) {
      throw CloudUnavailableException('Huawei Drive is unavailable on this device.', cause: error);
    } on PlatformException catch (error) {
      throw CloudStorageException(
        'Huawei Drive operation failed: ${error.message ?? error.code}',
        cause: error,
      );
    } on FileSystemException catch (error) {
      throw CloudStorageException('Huawei Drive staging file failed.', cause: error);
    } on Exception catch (error) {
      throw CloudStorageException('Huawei Drive operation failed.', cause: error);
    }
  }

  Future<List<huawei.DriveFile>> _matchingFiles(huawei.Drive drive, String name) async {
    final matches = (await _allFiles(drive)).where((file) => file.fileName == name).toList()
      ..sort((left, right) => compareBackupsNewestFirst(_file(left), _file(right)));
    return matches;
  }

  Future<List<huawei.DriveFile>> _allFiles(huawei.Drive drive) async {
    final result = <huawei.DriveFile>[];
    String? cursor;
    do {
      final page = await drive.files.list(
        huawei.FilesRequest.list(
          containers: _space,
          fields: _fields,
          pageSize: 100,
          cursor: cursor,
        ),
      );
      result.addAll(
        page.files.where(
          (file) => file.recycled != true && file.id != null && file.fileName != null,
        ),
      );
      cursor = page.nextCursor;
    } while (cursor != null && cursor.isNotEmpty);
    return result;
  }

  CloudBackupFile _file(huawei.DriveFile file, {String? fallbackName}) => CloudBackupFile(
    id: file.id ?? fallbackName ?? file.fileName!,
    name: file.fileName ?? fallbackName!,
    provider: provider,
    createdAt: file.createdTime,
    modifiedAt: file.editedTime,
    sizeInBytes: file.size,
  );

  void _validateSize(int size) {
    if (size > maxObjectSizeInBytes) {
      throw BackupFormatException(
        'Backup is $size bytes, exceeding the $maxObjectSizeInBytes byte limit.',
      );
    }
  }
}
