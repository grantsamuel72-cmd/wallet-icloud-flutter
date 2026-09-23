import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';
import 'package:wallet_cloud_backup_example/memory_backup_store.dart';

void main() {
  group('MemoryBackupStore', () {
    late MemoryBackupStore store;

    setUp(() => store = MemoryBackupStore());

    test('is always connected', () async {
      expect(await store.connect(), isTrue);
      expect(await store.connect(interactive: true), isTrue);
    });

    test('writes and reads copies of the bytes', () async {
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);

      final file = await store.write('a.json', bytes);
      bytes[0] = 9;
      final read = await store.read('a.json');
      read[1] = 9;

      expect(file.name, 'a.json');
      expect(file.sizeInBytes, 3);
      expect(await store.read('a.json'), <int>[1, 2, 3]);
    });

    test('lists the most recently written file first', () async {
      await store.write('old.json', Uint8List(1));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await store.write('new.json', Uint8List(1));

      expect((await store.list()).map((file) => file.name), <String>[
        'new.json',
        'old.json',
      ]);
    });

    test('deletes files and reports missing ones', () async {
      await store.write('a.json', Uint8List(1));

      await store.delete('a.json');

      expect(await store.list(), isEmpty);
      await expectLater(
        store.read('a.json'),
        throwsA(isA<BackupNotFoundException>()),
      );
      await expectLater(
        store.delete('a.json'),
        throwsA(isA<BackupNotFoundException>()),
      );
    });
  });
}
