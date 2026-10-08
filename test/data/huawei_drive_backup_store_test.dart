import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huawei_drive/huawei_drive.dart' as huawei;
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.huawei.hms.flutter.drive');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late _FakeHuaweiDrive fake;
  late HuaweiDriveBackupStore store;

  setUp(() {
    fake = _FakeHuaweiDrive();
    messenger.setMockMethodCallHandler(channel, fake.handle);
    store = HuaweiDriveBackupStore(
      credentialsProvider: ({required interactive}) async =>
          huawei.DriveCredentials(unionId: 'user', accessToken: 'token'),
      maxObjectSizeInBytes: 64,
    );
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('creates, updates, reads and deletes one app-data backup', () async {
    final first = await store.write('wallet.json', Uint8List.fromList(<int>[0, 128, 255]));
    expect(await store.read('wallet.json'), <int>[0, 128, 255]);
    final second = await store.write('wallet.json', Uint8List.fromList(<int>[1, 2, 3]));

    expect(first.provider, CloudBackupProvider.huaweiDrive);
    expect(second.id, first.id);
    expect(fake.files, hasLength(1));
    expect(fake.parentFolders.single, <String>['applicationData']);
    expect(await File(fake.uploadPaths.first).exists(), isFalse);
    expect(fake.listContainers, everyElement('applicationData'));
    expect(await store.read('wallet.json'), <int>[1, 2, 3]);
    expect((await store.list()).single.name, 'wallet.json');

    await store.delete('wallet.json');
    await expectLater(store.read('wallet.json'), throwsA(isA<BackupNotFoundException>()));
  });

  test('returns false when silent authorization is unavailable', () async {
    final unavailable = HuaweiDriveBackupStore(
      credentialsProvider: ({required interactive}) async => null,
    );
    expect(await unavailable.connect(), isFalse);
    await expectLater(unavailable.list(), throwsA(isA<CloudAuthenticationException>()));
  });

  test('rejects an oversized backup before touching Drive', () async {
    await expectLater(
      store.write('wallet.json', Uint8List(65)),
      throwsA(isA<BackupFormatException>()),
    );
    expect(fake.files, isEmpty);
  });

  test('refuses an operation after the HUAWEI ID changes', () async {
    var account = 'first';
    final guarded = HuaweiDriveBackupStore(
      credentialsProvider: ({required interactive}) async =>
          huawei.DriveCredentials(unionId: account, accessToken: 'token'),
    );
    expect(await guarded.connect(), isTrue);
    guarded.bindAccount('first');
    account = 'second';
    await expectLater(guarded.list(), throwsA(isA<CloudAuthenticationException>()));
    expect(guarded.accountId, isNull);
  });
}

class _FakeHuaweiDrive {
  final files = <String, _FakeFile>{};
  final parentFolders = <List<String>>[];
  final uploadPaths = <String>[];
  final listContainers = <String>[];
  int nextId = 0;

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'Drive#Init':
        return null;
      case 'Files#List':
        final request = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        listContainers.add(request['containers'] as String);
        return jsonEncode(<String, Object?>{
          'files': <Map<String, Object?>>[
            for (final entry in files.entries)
              <String, Object?>{
                'id': entry.key,
                'fileName': entry.value.name,
                'size': entry.value.content.length,
                'createdTime': '2026-01-01T00:00:00Z',
                'editedTime': '2026-01-01T00:00:00Z',
              },
          ],
        });
      case 'Files#Create':
        final args = call.arguments as Map<Object?, Object?>;
        final metadata = jsonDecode(args['file'] as String) as Map<String, dynamic>;
        final content = args['fileContent'] as Map<Object?, Object?>;
        uploadPaths.add(content['path'] as String);
        final id = 'file-${++nextId}';
        final name = metadata['fileName'] as String;
        parentFolders.add((metadata['parentFolder'] as List<Object?>).cast<String>());
        files[id] = _FakeFile(name, await File(content['path'] as String).readAsBytes());
        return jsonEncode(<String, Object?>{'id': id, 'fileName': name});
      case 'Files#Update':
        final args = call.arguments as Map<Object?, Object?>;
        final request = jsonDecode(args['request'] as String) as Map<String, dynamic>;
        final content = args['fileContent'] as Map<Object?, Object?>;
        uploadPaths.add(content['path'] as String);
        final id = request['fileId'] as String;
        files[id] = _FakeFile(files[id]!.name, await File(content['path'] as String).readAsBytes());
        return jsonEncode(<String, Object?>{'id': id, 'fileName': files[id]!.name});
      case 'Files#ExecuteContentAsInputStream':
        final request = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        return files[request['fileId']]!.content;
      case 'Files#Delete':
        final request = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        files.remove(request['fileId']);
        return true;
      default:
        throw MissingPluginException('Unexpected method ${call.method}');
    }
  }
}

class _FakeFile {
  const _FakeFile(this.name, this.content);

  final String name;
  final Uint8List content;
}
