import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

/// Exercises [ICloudPluginGateway] against `icloud_storage_plus`'s real Dart
/// layer, with the native side replaced by a fake method channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('icloud_storage_plus');
  const containerId = 'iCloud.com.example.wallet';
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late Map<String, Future<Object?> Function(MethodCall call)> native;

  ICloudBackupStore store({Duration syncTimeout = Duration.zero}) => ICloudBackupStore(
    containerId: containerId,
    syncTimeout: syncTimeout,
    gateway: const ICloudPluginGateway(),
  );

  Map<String, Object?> file(String path, {int? size, double? modified, bool directory = false}) =>
      <String, Object?>{
        'relativePath': path,
        'isDirectory': directory,
        'sizeInBytes': ?size,
        'contentChangeDate': ?modified,
      };

  PlatformException failure(String category) => PlatformException(
    code: 'E_TEST',
    message: category,
    details: <String, Object?>{'category': category, 'operation': 'test'},
  );

  setUp(() {
    calls = <MethodCall>[];
    native = <String, Future<Object?> Function(MethodCall call)>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final handler = native[call.method];
      if (handler == null) {
        throw MissingPluginException(call.method);
      }
      return handler(call);
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  List<String> methods() => calls.map((call) => call.method).toList();

  test('reports availability and treats a missing plugin as unavailable', () async {
    native['icloudAvailable'] = (_) async => true;
    expect(await store().connect(), isTrue);

    native.remove('icloudAvailable');
    expect(await store().connect(), isFalse);
  });

  group('list', () {
    test('merges iCloud metadata with the local folder listing', () async {
      native['gather'] = (_) async => <Object?>[
        file('WalletBackups/a.json', size: 10, modified: 1800000000),
        file('WalletBackups/remote-only.json', size: 20, modified: 1700000000),
        file('WalletBackups/nested/x.json', size: 1),
        file('Documents/other.json', size: 1),
        file('WalletBackups/folder', directory: true),
      ];
      native['listContents'] = (_) async => <Object?>[
        file('WalletBackups/a.json'),
        file('WalletBackups/local-only.json'),
      ];

      // The Spotlight index has not caught up with this one yet, so its
      // attributes come straight off the file system instead.
      native['getItemMetadata'] = (call) async {
        final path = (call.arguments as Map<Object?, Object?>)['relativePath'];
        return path == 'WalletBackups/local-only.json'
            ? file(path! as String, size: 30, modified: 1900000000)
            : null;
      };

      final files = await store().list();

      // Newest first, including the entry the metadata query does not know.
      expect(files.map((f) => f.name), <String>['local-only.json', 'a.json', 'remote-only.json']);
      expect(files[1].sizeInBytes, 10, reason: 'metadata comes from the iCloud query');
      expect(files[1].modifiedAt, DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000));
      expect(files.first.sizeInBytes, 30, reason: 'metadata comes from the file system');
      expect(files.first.modifiedAt, DateTime.fromMillisecondsSinceEpoch(1900000000 * 1000));
      final listCall = calls.singleWhere((call) => call.method == 'listContents');
      expect((listCall.arguments as Map<Object?, Object?>)['relativePath'], 'WalletBackups');
    });

    // getItemMetadata validates the path in Dart before the channel call and
    // throws InvalidArgumentException, which is not an ICloudOperationException.
    // A single foreign file must not cost the caller the whole listing.
    test('keeps a local-only file whose name the plugin refuses to look up', () async {
      native['gather'] = (_) async => <Object?>[
        file('WalletBackups/a.json', size: 10, modified: 1800000000),
      ];
      native['listContents'] = (_) async => <Object?>[
        file('WalletBackups/odd:name.json'),
        file('WalletBackups/local-only.json'),
      ];
      native['getItemMetadata'] = (call) async {
        final path = (call.arguments as Map<Object?, Object?>)['relativePath'];
        return file(path! as String, size: 30, modified: 1900000000);
      };

      final files = await store().list();

      expect(files.map((f) => f.name), containsAll(<String>['a.json', 'odd:name.json']));
      expect(
        files.singleWhere((f) => f.name == 'odd:name.json').sizeInBytes,
        isNull,
        reason: 'listed without attributes rather than dropped or thrown',
      );
    });

    test('keeps a local-only file even when its attributes cannot be read', () async {
      native['gather'] = (_) async => <Object?>[
        file('WalletBackups/a.json', size: 10, modified: 1800000000),
      ];
      native['listContents'] = (_) async => <Object?>[file('WalletBackups/local-only.json')];
      // getItemMetadata is deliberately not registered: the plugin turns the
      // missing implementation into an ICloudOperationException.

      final files = await store().list();

      expect(files.map((f) => f.name), <String>['a.json', 'local-only.json']);
      expect(files.last.sizeInBytes, isNull);
      expect(files.last.modifiedAt, isNull);
    });

    test('falls back to iCloud metadata when the folder does not exist locally', () async {
      native['gather'] = (_) async => <Object?>[file('WalletBackups/a.json', size: 10)];
      native['listContents'] = (_) async => throw failure('itemNotFound');

      final files = await store().list();

      expect(files.map((f) => f.name), <String>['a.json']);
    });
  });

  group('read', () {
    test('passes the container and path to the plugin', () async {
      native['readInPlaceBytes'] = (_) async => Uint8List.fromList(<int>[1, 2]);

      expect(await store().read('a.json'), <int>[1, 2]);
      expect(calls.single.arguments, <String, Object?>{
        'containerId': containerId,
        'relativePath': 'WalletBackups/a.json',
      });
    });

    test('maps native error categories to package exceptions', () async {
      native['readInPlaceBytes'] = (_) async => throw failure('itemNotFound');
      await expectLater(store().read('a.json'), throwsA(isA<BackupNotFoundException>()));

      native['readInPlaceBytes'] = (_) async => throw failure('containerAccess');
      await expectLater(store().read('a.json'), throwsA(isA<CloudUnavailableException>()));

      native['readInPlaceBytes'] = (_) async => throw failure('coordination');
      await expectLater(store().read('a.json'), throwsA(isA<CloudStorageException>()));
    });

    test('waits for iCloud to deliver a file that is not on this device yet', () async {
      var reads = 0;
      native['readInPlaceBytes'] = (_) async {
        reads += 1;
        if (reads == 1) {
          throw failure('itemNotFound');
        }
        return Uint8List.fromList(<int>[7]);
      };
      native['createEventChannel'] = (call) async {
        final name = (call.arguments as Map<Object?, Object?>)['eventChannelName']! as String;
        messenger.setMockStreamHandler(
          EventChannel(name),
          MockStreamHandler.inline(
            onListen: (_, events) => Timer(
              const Duration(milliseconds: 20),
              () => events.success(<Object?>[file('WalletBackups/a.json', size: 1)]),
            ),
          ),
        );
        return null;
      };
      native['gather'] = (_) async => <Object?>[];

      final bytes = await store(syncTimeout: const Duration(seconds: 5)).read('a.json');

      expect(bytes, <int>[7]);
      expect(methods(), <String>[
        'readInPlaceBytes',
        'createEventChannel',
        'gather',
        'readInPlaceBytes',
      ]);
    });

    test('gives up after the sync timeout', () async {
      native['readInPlaceBytes'] = (_) async => throw failure('itemNotFound');
      native['createEventChannel'] = (call) async {
        final name = (call.arguments as Map<Object?, Object?>)['eventChannelName']! as String;
        messenger.setMockStreamHandler(
          EventChannel(name),
          MockStreamHandler.inline(onListen: (_, _) {}),
        );
        return null;
      };
      native['gather'] = (_) async => <Object?>[];

      await expectLater(
        store(syncTimeout: const Duration(milliseconds: 50)).read('a.json'),
        throwsA(isA<BackupNotFoundException>()),
      );
    });
  });

  test('writes bytes in place and returns the item metadata', () async {
    native['writeInPlaceBytes'] = (_) async => null;
    native['getItemMetadata'] = (_) async => file('WalletBackups/a.json', size: 3);

    final written = await store().write('a.json', Uint8List.fromList(<int>[1, 2, 3]));

    final write = calls.first.arguments as Map<Object?, Object?>;
    expect(write['relativePath'], 'WalletBackups/a.json');
    expect(write['contents'], <int>[1, 2, 3]);
    expect(written.name, 'a.json');
    expect(written.sizeInBytes, 3);
  });

  test('maps conflict versions and resolves them explicitly', () async {
    native['enumerateUnresolvedConflictVersions'] = (_) async => <Object?>[
      <String, Object?>{'identifier': 'v1', 'modificationDate': 1800000000},
    ];
    native['markConflictResolved'] = (_) async => null;
    final backups = store();

    final versions = await backups.listConflicts('a.json');
    await backups.resolveConflicts(
      'a.json',
      reviewedVersionIds: <String>{'v1'},
      removeOtherVersions: true,
    );

    expect(versions.single.id, 'v1');
    expect(versions.single.modifiedAt, DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000));
    final resolve = calls.last.arguments as Map<Object?, Object?>;
    expect(calls.last.method, 'markConflictResolved');
    expect(resolve['removeOtherVersions'], isTrue);
  });
}
