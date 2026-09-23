import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:icloud_storage_plus/icloud_storage.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  group('ICloudBackupStore', () {
    late _FakeICloudGateway gateway;
    late ICloudBackupStore store;

    setUp(() {
      gateway = _FakeICloudGateway();
      store = ICloudBackupStore(containerId: 'iCloud.com.example.wallet', gateway: gateway);
    });

    test('keeps backups outside the Files-visible Documents folder', () async {
      await store.write('wallet-backup.json', Uint8List.fromList(<int>[1, 2, 3]));

      expect(gateway.files.keys, <String>['WalletBackups/wallet-backup.json']);
    });

    test('reports unavailable instead of throwing when the plugin fails', () async {
      gateway.availability = const ICloudOperationException.pluginContract(
        operation: 'icloudAvailable',
        message: 'Missing native plugin implementation',
      );

      expect(await store.connect(), isFalse);
    });

    test('waits for iCloud to sync a file missing on this device', () async {
      gateway.pendingSync['WalletBackups/a.json'] = Uint8List.fromList(<int>[7]);

      expect(await store.read('a.json'), <int>[7]);
      expect(gateway.waitCalls, 1);
    });

    test('retries while the local placeholder is being created', () async {
      gateway
        ..pendingSync['WalletBackups/a.json'] = Uint8List.fromList(<int>[7])
        ..placeholderMisses = 1;

      expect(await store.read('a.json'), <int>[7]);
      expect(gateway.readCalls, 3);
      // One metadata query is enough: re-running it while the placeholder is
      // being written would only re-answer a question already answered.
      expect(gateway.waitCalls, 1);
    });

    test('times out an iCloud call that never finishes', () async {
      gateway.hangReads = true;
      store = ICloudBackupStore(
        containerId: 'iCloud.com.example.wallet',
        operationTimeout: const Duration(milliseconds: 50),
        gateway: gateway,
      );

      await expectLater(store.read('a.json'), throwsA(isA<CloudStorageException>()));
    });

    test('reports not found after the sync timeout', () async {
      await expectLater(store.read('a.json'), throwsA(isA<BackupNotFoundException>()));
      expect(gateway.waitCalls, 1);
    });

    test('does not wait when syncTimeout is zero', () async {
      store = ICloudBackupStore(
        containerId: 'iCloud.com.example.wallet',
        syncTimeout: Duration.zero,
        gateway: gateway,
      );

      await expectLater(store.read('a.json'), throwsA(isA<BackupNotFoundException>()));
      expect(gateway.waitCalls, 0);
    });

    test('maps container access failures to CloudUnavailableException', () async {
      gateway.failure = const ICloudContainerAccessException(
        operation: 'writeInPlaceBytes',
        retryable: false,
        message: 'No ubiquity container',
      );

      await expectLater(
        store.write('a.json', Uint8List(1)),
        throwsA(isA<CloudUnavailableException>()),
      );
    });

    test('sorts listed files newest first', () async {
      gateway.entries = <ICloudBackupEntry>[
        ICloudBackupEntry(relativePath: 'WalletBackups/old.json', modifiedAt: DateTime.utc(2025)),
        const ICloudBackupEntry(relativePath: 'WalletBackups/unknown.json'),
        ICloudBackupEntry(relativePath: 'WalletBackups/new.json', modifiedAt: DateTime.utc(2026)),
      ];

      final names = (await store.list()).map((file) => file.name);

      expect(names, <String>['new.json', 'old.json', 'unknown.json']);
    });

    // An empty name used to build 'WalletBackups/', which the plugin happily
    // hands to FileManager.removeItem — a recursive delete of every backup.
    test('refuses a file name that is not a plain file name', () async {
      await store.write('a.json', Uint8List.fromList(<int>[1]));
      for (final fileName in <String>['', '   ', 'nested/a.json', '.a.json']) {
        await expectLater(store.delete(fileName), throwsA(isA<ArgumentError>()));
        await expectLater(store.read(fileName), throwsA(isA<ArgumentError>()));
        await expectLater(store.write(fileName, Uint8List(1)), throwsA(isA<ArgumentError>()));
      }
      expect(
        gateway.files.keys,
        <String>['WalletBackups/a.json'],
        reason: 'an existing backup must survive every rejected name',
      );
    });

    // The bytes are already on disk by then, so a metadata failure must not
    // turn a successful write into an error — nor hang it, nor leak a
    // provider exception out of the store's contract.
    test('still reports a successful write when metadata cannot be read', () async {
      store = ICloudBackupStore(
        containerId: 'iCloud.com.example.wallet',
        operationTimeout: const Duration(milliseconds: 50),
        gateway: gateway,
      );

      gateway.hangMetadata = true;
      expect((await store.write('a.json', Uint8List(3))).sizeInBytes, 3);

      gateway
        ..hangMetadata = false
        ..metadataFailure = InvalidArgumentException('invalid relativePath');
      expect((await store.write('b.json', Uint8List(4))).sizeInBytes, 4);
    });

    test('refuses objects over the size limit on both read paths', () async {
      store = ICloudBackupStore(
        containerId: 'iCloud.com.example.wallet',
        maxObjectSizeInBytes: 4,
        gateway: gateway,
      );
      gateway.files['WalletBackups/big.json'] = Uint8List(5);

      await expectLater(store.read('big.json'), throwsA(isA<BackupFormatException>()));
      await expectLater(
        store.write('big.json', Uint8List(5)),
        throwsA(isA<BackupFormatException>()),
      );
      gateway.conflictBytes = Uint8List(5);
      await expectLater(
        store.readConflictVersion('big.json', 'version-1'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('reads a conflict version through a temporary file', () async {
      final bytes = await store.readConflictVersion('a.json', 'version-1');

      expect(bytes, <int>[9, 9]);
      expect(gateway.lastCopyDestination, endsWith('/a.json'));
      expect(File(gateway.lastCopyDestination!).existsSync(), isFalse);
    });

    test('refuses to resolve when an unreviewed version appeared', () async {
      gateway.conflictIds = <String>['version-1', 'version-2'];

      await expectLater(
        store.resolveConflicts(
          'a.json',
          reviewedVersionIds: <String>{'version-1'},
          removeOtherVersions: true,
        ),
        throwsA(
          isA<BackupConflictException>().having(
            (error) => error.unreviewedVersionIds,
            'unreviewedVersionIds',
            <String>{'version-2'},
          ),
        ),
      );
      expect(gateway.resolveCalls, 0);
    });

    test('resolves after every version was reviewed', () async {
      gateway.conflictIds = <String>['version-1', 'version-2'];

      await store.resolveConflicts(
        'a.json',
        reviewedVersionIds: <String>{'version-1', 'version-2'},
        removeOtherVersions: true,
      );

      expect(gateway.resolveCalls, 1);
      expect(gateway.removeOtherVersions, isTrue);
    });
  });
}

class _FakeICloudGateway implements ICloudStorageGateway {
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final Map<String, Uint8List> pendingSync = <String, Uint8List>{};
  List<ICloudBackupEntry> entries = const <ICloudBackupEntry>[];
  List<String> conflictIds = const <String>['version-1'];
  Object? availability;
  ICloudOperationException? failure;
  String? lastCopyDestination;
  Uint8List conflictBytes = Uint8List.fromList(<int>[9, 9]);
  bool hangReads = false;
  bool hangMetadata = false;
  Object? metadataFailure;
  int placeholderMisses = 0;
  int readCalls = 0;
  int waitCalls = 0;
  int resolveCalls = 0;
  bool removeOtherVersions = false;

  void _maybeFail() {
    if (failure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (availability case final error?) {
      throw error;
    }
    return true;
  }

  @override
  Future<void> write(String containerId, String relativePath, Uint8List contents) async {
    _maybeFail();
    files[relativePath] = contents;
  }

  @override
  Future<Uint8List> read(String containerId, String relativePath) async {
    _maybeFail();
    readCalls += 1;
    if (hangReads) {
      return Completer<Uint8List>().future;
    }
    final contents = files[relativePath];
    if (contents == null || (waitCalls > 0 && placeholderMisses-- > 0)) {
      throw ICloudItemNotFoundException(
        operation: 'readInPlaceBytes',
        retryable: false,
        message: 'Not found',
        relativePath: relativePath,
      );
    }
    return contents;
  }

  @override
  Future<void> delete(String containerId, String relativePath) async {
    _maybeFail();
    // Matches FileManager.removeItem, which the plugin calls: a directory
    // path takes everything under it with it.
    files.removeWhere(
      (path, _) => path == relativePath || path.startsWith('$relativePath/'),
    );
  }

  @override
  Future<ICloudBackupEntry?> metadata(String containerId, String relativePath) async {
    if (hangMetadata) {
      return Completer<ICloudBackupEntry?>().future;
    }
    if (metadataFailure case final failure?) {
      throw failure;
    }
    return ICloudBackupEntry(relativePath: relativePath, sizeInBytes: files[relativePath]?.length);
  }

  @override
  Future<List<ICloudBackupEntry>> list(String containerId, String folder) async => entries;

  @override
  Future<bool> waitForItem(String containerId, String relativePath, Duration timeout) async {
    waitCalls += 1;
    final synced = pendingSync.remove(relativePath);
    if (synced != null) {
      files[relativePath] = synced;
    }
    return files.containsKey(relativePath);
  }

  @override
  Future<List<BackupConflictVersion>> conflicts(String containerId, String relativePath) async =>
      <BackupConflictVersion>[for (final id in conflictIds) BackupConflictVersion(id: id)];

  @override
  Future<void> copyConflict(
    String containerId,
    String relativePath,
    String versionId,
    String localDestinationPath,
  ) async {
    lastCopyDestination = localDestinationPath;
    await File(localDestinationPath).writeAsBytes(conflictBytes);
  }

  @override
  Future<void> resolveConflicts(
    String containerId,
    String relativePath, {
    required bool removeOtherVersions,
  }) async {
    resolveCalls += 1;
    this.removeOtherVersions = removeOtherVersions;
  }
}
