import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:icloud_storage_plus/icloud_storage.dart';
import 'package:wallet_cloud_backup/src/domain/backup_file_names.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_file.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_store.dart';
import 'package:wallet_cloud_backup/src/domain/exceptions.dart';

/// Narrow gateway around `icloud_storage_plus`, replaceable in tests.
///
/// Implementations may throw `icloud_storage_plus` exceptions; the store maps
/// them to [WalletCloudBackupException] subclasses.
abstract interface class ICloudStorageGateway {
  /// Whether iCloud Drive is available.
  Future<bool> isAvailable();

  /// Writes bytes using coordinated in-place access.
  Future<void> write(String containerId, String relativePath, Uint8List contents);

  /// Reads bytes using coordinated in-place access.
  Future<Uint8List> read(String containerId, String relativePath);

  /// Deletes an item.
  Future<void> delete(String containerId, String relativePath);

  /// Retrieves metadata for one item.
  Future<ICloudBackupEntry?> metadata(String containerId, String relativePath);

  /// Lists files directly below [folder].
  Future<List<ICloudBackupEntry>> list(String containerId, String folder);

  /// Waits up to [timeout] for iCloud metadata to report [relativePath].
  ///
  /// Returns whether the item appeared.
  Future<bool> waitForItem(String containerId, String relativePath, Duration timeout);

  /// Lists unresolved versions.
  Future<List<BackupConflictVersion>> conflicts(String containerId, String relativePath);

  /// Copies one losing conflict version to a caller-owned local path.
  Future<void> copyConflict(
    String containerId,
    String relativePath,
    String versionId,
    String localDestinationPath,
  );

  /// Marks all unresolved versions as resolved.
  Future<void> resolveConflicts(
    String containerId,
    String relativePath, {
    required bool removeOtherVersions,
  });
}

/// Provider-neutral subset of iCloud metadata used by the store.
class ICloudBackupEntry {
  /// Creates iCloud entry metadata.
  const ICloudBackupEntry({
    required this.relativePath,
    this.createdAt,
    this.modifiedAt,
    this.sizeInBytes,
    this.hasUnresolvedConflicts = false,
  });

  /// Path relative to the ubiquity container.
  final String relativePath;

  /// Creation time.
  final DateTime? createdAt;

  /// Last content change time.
  final DateTime? modifiedAt;

  /// File size.
  final int? sizeInBytes;

  /// Whether unresolved versions exist.
  final bool hasUnresolvedConflicts;
}

/// Production gateway backed by `icloud_storage_plus`.
class ICloudPluginGateway implements ICloudStorageGateway {
  /// Creates the stateless gateway.
  const ICloudPluginGateway();

  @override
  Future<bool> isAvailable() => ICloudStorage.icloudAvailable();

  @override
  Future<void> write(String containerId, String relativePath, Uint8List contents) {
    return ICloudStorage.writeInPlaceBytes(
      containerId: containerId,
      relativePath: relativePath,
      contents: contents,
    );
  }

  @override
  Future<Uint8List> read(String containerId, String relativePath) {
    return ICloudStorage.readInPlaceBytes(containerId: containerId, relativePath: relativePath);
  }

  @override
  Future<void> delete(String containerId, String relativePath) {
    return ICloudStorage.delete(containerId: containerId, relativePath: relativePath);
  }

  @override
  Future<ICloudBackupEntry?> metadata(String containerId, String relativePath) async {
    final metadata = await ICloudStorage.getItemMetadata(
      containerId: containerId,
      relativePath: relativePath,
    );
    if (metadata == null || metadata.isDirectory) {
      return null;
    }
    return ICloudBackupEntry(
      relativePath: metadata.relativePath,
      createdAt: metadata.creationDate,
      modifiedAt: metadata.contentChangeDate,
      sizeInBytes: metadata.sizeInBytes,
      hasUnresolvedConflicts: metadata.hasUnresolvedConflicts,
    );
  }

  @override
  Future<List<ICloudBackupEntry>> list(String containerId, String folder) async {
    final prefix = '$folder/';
    bool isDirectChild(String path) =>
        path.startsWith(prefix) && !path.substring(prefix.length).contains('/');

    // Spotlight metadata carries sizes and dates, but is eventually consistent.
    final gathered = <String, ICloudBackupEntry>{
      for (final file in (await ICloudStorage.gather(containerId: containerId)).files)
        if (!file.isDirectory && isDirectChild(file.relativePath))
          file.relativePath: ICloudBackupEntry(
            relativePath: file.relativePath,
            createdAt: file.creationDate,
            modifiedAt: file.contentChangeDate,
            sizeInBytes: file.sizeInBytes,
            hasUnresolvedConflicts: file.hasUnresolvedConflicts,
          ),
    };

    // The file system listing immediately shows this device's own writes.
    // Files known only to the metadata query are kept too: hiding a real
    // backup is worse than briefly showing one this device just deleted.
    List<ContainerItem> local;
    try {
      local = await ICloudStorage.listContents(containerId: containerId, relativePath: folder);
    } on ICloudOperationException {
      // The folder does not exist locally yet, e.g. before the first backup.
      local = const <ContainerItem>[];
    }
    final entries = Map<String, ICloudBackupEntry>.of(gathered);
    for (final item in local) {
      if (item.isDirectory || !isDirectChild(item.relativePath) ||
          entries.containsKey(item.relativePath)) {
        continue;
      }
      // ContainerItem carries no dates or size, and these are usually this
      // device's own fresh writes — the entries a "newest first" list most
      // needs to place correctly. Read them straight off the file system,
      // which is immediately consistent, unlike the Spotlight query above.
      ICloudBackupEntry? attributes;
      try {
        attributes = await metadata(containerId, item.relativePath);
      } on ICloudOperationException {
        // Informational only; fall back to the bare entry.
      } on InvalidArgumentException {
        // A name the plugin refuses to look up, e.g. one containing ':'.
        // Listing the file without its attributes beats failing the listing.
      }
      entries[item.relativePath] =
          attributes ??
          ICloudBackupEntry(
            relativePath: item.relativePath,
            hasUnresolvedConflicts: item.hasUnresolvedConflicts,
          );
    }
    return entries.values.toList(growable: false);
  }

  @override
  Future<bool> waitForItem(String containerId, String relativePath, Duration timeout) async {
    bool contains(GatherResult result) =>
        result.files.any((file) => !file.isDirectory && file.relativePath == relativePath);

    final appeared = Completer<bool>();
    StreamSubscription<GatherResult>? subscription;
    try {
      final initial = await ICloudStorage.gather(
        containerId: containerId,
        // The plugin requires the listener to be attached synchronously here.
        onUpdate: (updates) {
          subscription = updates.listen(
            (result) {
              if (!appeared.isCompleted && contains(result)) {
                appeared.complete(true);
              }
            },
            onError: (Object _) {
              if (!appeared.isCompleted) {
                appeared.complete(false);
              }
            },
          );
        },
      );
      if (contains(initial)) {
        return true;
      }
      return await appeared.future.timeout(timeout, onTimeout: () => false);
    } finally {
      await subscription?.cancel();
    }
  }

  @override
  Future<List<BackupConflictVersion>> conflicts(String containerId, String relativePath) async {
    final versions = await ICloudStorage.enumerateUnresolvedConflictVersions(
      containerId: containerId,
      relativePath: relativePath,
    );
    return versions
        .map(
          (version) =>
              BackupConflictVersion(id: version.identifier, modifiedAt: version.modificationDate),
        )
        .toList(growable: false);
  }

  @override
  Future<void> copyConflict(
    String containerId,
    String relativePath,
    String versionId,
    String localDestinationPath,
  ) {
    return ICloudStorage.copyConflictVersion(
      containerId: containerId,
      relativePath: relativePath,
      versionIdentifier: versionId,
      destinationPath: localDestinationPath,
    );
  }

  @override
  Future<void> resolveConflicts(
    String containerId,
    String relativePath, {
    required bool removeOtherVersions,
  }) {
    return ICloudStorage.markConflictResolved(
      containerId: containerId,
      relativePath: relativePath,
      removeOtherVersions: removeOtherVersions,
    );
  }
}

/// iCloud Drive backend using an app-owned ubiquity container.
class ICloudBackupStore implements ConflictAwareBackupStore {
  /// Creates an iCloud backend.
  ICloudBackupStore({
    required this.containerId,
    String folder = 'WalletBackups',
    this.syncTimeout = const Duration(seconds: 10),
    this.maxObjectSizeInBytes = defaultMaxBackupSizeInBytes,
    this.operationTimeout = const Duration(seconds: 60),
    ICloudStorageGateway? gateway,
  }) : folder = _validateFolder(folder),
       _gateway = gateway ?? const ICloudPluginGateway() {
    if (containerId.trim().isEmpty) {
      throw ArgumentError.value(containerId, 'containerId', 'Must not be empty.');
    }
    if (maxObjectSizeInBytes <= 0) {
      throw ArgumentError.value(maxObjectSizeInBytes, 'maxObjectSizeInBytes', 'Must be positive.');
    }
  }

  /// Apple ubiquity container identifier, for example `iCloud.com.example.wallet`.
  final String containerId;

  /// App-managed folder. It intentionally does not use the Files-visible `Documents/` prefix.
  final String folder;

  /// How long [read] waits for iCloud to sync a file that is not on this device yet.
  ///
  /// Relevant on a newly set up device. [Duration.zero] disables waiting.
  final Duration syncTimeout;

  /// Maximum accepted object size.
  ///
  /// iCloud hands back whole files, so unlike the Drive backend this is a
  /// rejection threshold rather than a bound on peak memory: an oversized
  /// object is read before it is refused. Pre-checking against the Spotlight
  /// index instead would risk refusing a valid backup on a stale size.
  final int maxObjectSizeInBytes;

  /// Upper bound for one iCloud call, e.g. a download while offline, before it
  /// fails with [CloudStorageException].
  final Duration operationTimeout;

  final ICloudStorageGateway _gateway;

  // Delay between reads while iCloud creates the local placeholder of a file
  // that its metadata already reports.
  static const Duration _placeholderRetryDelay = Duration(milliseconds: 500);

  @override
  CloudBackupProvider get provider => CloudBackupProvider.iCloud;

  /// Returns whether iCloud Drive is usable. iCloud has no in-app sign-in UI,
  /// so [interactive] has no effect.
  @override
  Future<bool> connect({bool interactive = false}) async {
    try {
      return await _gateway.isAvailable();
    } on ICloudOperationException {
      return false;
    }
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<CloudBackupFile> write(String fileName, Uint8List contents) async {
    _validateSize(contents.length);
    final path = _path(fileName);
    await _guard(fileName, () => _gateway.write(containerId, path, contents));
    ICloudBackupEntry? metadata;
    try {
      metadata = await _guard(fileName, () => _gateway.metadata(containerId, path));
    } on WalletCloudBackupException {
      // The write succeeded; metadata is informational only. Going through
      // _guard keeps this call under operationTimeout and stops provider
      // exceptions from escaping the store's contract.
    }
    return _toCloudFile(
      metadata ?? ICloudBackupEntry(relativePath: path, sizeInBytes: contents.length),
    );
  }

  @override
  Future<Uint8List> read(String fileName) async {
    final path = _path(fileName);
    // A monotonic clock: the retry delay and the timeouts below use one too,
    // and a clock correction mid-wait must not stretch or cut this window.
    final elapsed = Stopwatch()..start();
    var waited = false;
    while (true) {
      try {
        final bytes = await _guard(fileName, () => _gateway.read(containerId, path));
        _validateSize(bytes.length);
        return bytes;
      } on BackupNotFoundException {
        // A new device may learn about the file from iCloud metadata before
        // its local placeholder exists, so keep trying until the deadline.
        final remaining = syncTimeout - elapsed.elapsed;
        if (remaining <= Duration.zero) rethrow;
        if (waited) {
          // Waiting again would only re-run the same container-wide metadata
          // query; the file is already known, just not materialized yet.
          await Future<void>.delayed(
            remaining < _placeholderRetryDelay ? remaining : _placeholderRetryDelay,
          );
        } else {
          waited = true;
          if (!await _guard(
            fileName,
            () => _gateway.waitForItem(containerId, path, remaining),
            timeout: remaining + operationTimeout,
          )) {
            rethrow;
          }
        }
      }
    }
  }

  @override
  Future<List<CloudBackupFile>> list() async {
    final entries = await _guard(null, () => _gateway.list(containerId, folder));
    final files = entries.map(_toCloudFile).toList()..sort(compareBackupsNewestFirst);
    return List<CloudBackupFile>.unmodifiable(files);
  }

  @override
  Future<void> delete(String fileName) {
    return _guard(fileName, () => _gateway.delete(containerId, _path(fileName)));
  }

  @override
  Future<List<BackupConflictVersion>> listConflicts(String fileName) {
    return _guard(fileName, () => _gateway.conflicts(containerId, _path(fileName)));
  }

  @override
  Future<Uint8List> readConflictVersion(String fileName, String versionId) async {
    if (versionId.trim().isEmpty) {
      throw ArgumentError.value(versionId, 'versionId', 'Must not be empty.');
    }
    final Directory directory;
    try {
      directory = await Directory.systemTemp.createTemp('wallet_cloud_backup_');
    } on FileSystemException catch (error) {
      throw CloudStorageException('Could not create a temporary directory.', cause: error);
    }
    try {
      // Same name as the original, in case Foundation keeps the file name when replacing.
      final destination = File('${directory.path}/$fileName');
      await _guard(
        fileName,
        () => _gateway.copyConflict(containerId, _path(fileName), versionId, destination.path),
      );
      _validateSize(await destination.length());
      return await destination.readAsBytes();
    } on FileSystemException catch (error) {
      throw CloudStorageException('Could not read conflict version "$versionId".', cause: error);
    } finally {
      try {
        await directory.delete(recursive: true);
      } on FileSystemException {
        // The OS purges the temporary directory eventually.
      }
    }
  }

  @override
  Future<void> resolveConflicts(
    String fileName, {
    required Set<String> reviewedVersionIds,
    required bool removeOtherVersions,
  }) async {
    final path = _path(fileName);
    // Re-list right before resolving so a version that synced after the
    // caller's review is not removed unseen. The plugin resolves whatever is
    // unresolved when it runs, so a tiny window remains between these calls.
    final current = await _guard(fileName, () => _gateway.conflicts(containerId, path));
    final unreviewed = {for (final version in current) version.id}.difference(reviewedVersionIds);
    if (unreviewed.isNotEmpty) {
      throw BackupConflictException(unreviewed);
    }
    if (current.isEmpty) {
      return;
    }
    await _guard(
      fileName,
      () => _gateway.resolveConflicts(containerId, path, removeOtherVersions: removeOtherVersions),
    );
  }

  Future<T> _guard<T>(String? fileName, Future<T> Function() action, {Duration? timeout}) async {
    try {
      return await action().timeout(timeout ?? operationTimeout);
    } on TimeoutException catch (error) {
      throw CloudStorageException('iCloud did not respond in time.', cause: error);
    } on ICloudItemNotFoundException catch (error) {
      throw BackupNotFoundException(fileName ?? error.relativePath ?? folder, cause: error);
    } on ICloudContainerAccessException catch (error) {
      throw CloudUnavailableException(
        'iCloud container "$containerId" is not accessible. Check that the user is signed in '
        'to iCloud, iCloud Drive is enabled for this app, and the container is configured.',
        cause: error,
      );
    } on ICloudOperationException catch (error) {
      throw CloudStorageException(
        'iCloud ${error.operation} failed: ${error.message}',
        cause: error,
      );
    } on InvalidArgumentException catch (error) {
      throw CloudStorageException('iCloud rejected the request: $error', cause: error);
    }
  }

  void _validateSize(int size) {
    if (size > maxObjectSizeInBytes) {
      throw BackupFormatException(
        'iCloud object is $size bytes, exceeding the $maxObjectSizeInBytes byte limit.',
      );
    }
  }

  String _path(String fileName) => '$folder/${assertPlainBackupFileName(fileName)}';

  CloudBackupFile _toCloudFile(ICloudBackupEntry entry) => CloudBackupFile(
    id: entry.relativePath,
    name: entry.relativePath.substring(entry.relativePath.lastIndexOf('/') + 1),
    provider: provider,
    createdAt: entry.createdAt,
    modifiedAt: entry.modifiedAt,
    sizeInBytes: entry.sizeInBytes,
    hasUnresolvedConflicts: entry.hasUnresolvedConflicts,
  );

  static String _validateFolder(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final invalid =
        normalized.isEmpty ||
        normalized
            .split('/')
            .any(
              (segment) =>
                  segment.isEmpty ||
                  segment.startsWith('.') ||
                  segment.contains(':') ||
                  segment.length > 200,
            );
    if (invalid) {
      throw ArgumentError.value(value, 'folder', 'Must be a valid iCloud-relative folder.');
    }
    return normalized;
  }
}
