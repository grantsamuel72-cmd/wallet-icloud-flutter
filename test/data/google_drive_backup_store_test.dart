import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  group('GoogleDriveBackupStore', () {
    late _FakeDriveServer server;
    late _FakeTokenProvider tokens;
    late GoogleDriveBackupStore store;

    setUp(() {
      server = _FakeDriveServer();
      tokens = _FakeTokenProvider();
      store = GoogleDriveBackupStore(
        tokenProvider: tokens,
        httpClient: MockClient(server.handle),
        maxObjectSizeInBytes: 64,
      );
    });

    test('creates in appDataFolder, then updates the same file', () async {
      final created = await store.write('a.json', _bytes('first'));
      final updated = await store.write('a.json', _bytes('second'));

      expect(updated.id, created.id);
      expect(server.files, hasLength(1));
      expect(server.files.single.parents, <String>['appDataFolder']);
      expect(utf8.decode(await store.read('a.json')), 'second');
      expect(
        server.listRequests.every((url) => url.queryParameters['spaces'] == 'appDataFolder'),
        isTrue,
      );
    });

    // The contract says "newest first". Drive is asked to order the page, but
    // list() sorts locally too, so both backends answer the same way even if a
    // provider ignores the hint.
    test('lists newest first whatever order the server returns', () async {
      server
        ..seed('old.json', 'o', DateTime.utc(2025))
        ..seed('new.json', 'n', DateTime.utc(2026))
        ..seed('middle.json', 'm', DateTime.utc(2025, 6));
      server.honorOrderBy = false;

      expect((await store.list()).map((file) => file.name), <String>[
        'new.json',
        'middle.json',
        'old.json',
      ]);
    });

    test('lists and deletes files', () async {
      await store.write('a.json', _bytes('a'));
      await store.write('b.json', _bytes('b'));

      expect(
        (await store.list()).map((file) => file.name),
        unorderedEquals(<String>['a.json', 'b.json']),
      );

      await store.delete('a.json');
      expect((await store.list()).map((file) => file.name), <String>['b.json']);
      await expectLater(store.delete('a.json'), throwsA(isA<BackupNotFoundException>()));
    });

    // Drive's appDataFolder allows two files to share a name (two offline
    // devices both creating one). Everything here depends on the server-side
    // `orderBy: modifiedTime desc` that makes matches.first the newest.
    group('duplicate file names', () {
      setUp(() {
        server
          ..seed('a.json', 'o', DateTime.utc(2026, 1, 1))
          ..seed('a.json', 'nnnnn', DateTime.utc(2026, 6, 1));
      });

      test('read returns the newest copy', () async {
        expect(utf8.decode(await store.read('a.json')), 'nnnnn');
      });

      test('list reports the newest copy first', () async {
        expect((await store.list()).map((file) => file.id), <String>['file-2', 'file-1']);
      });

      test('write updates the newest copy and removes the stale ones', () async {
        final written = await store.write('a.json', _bytes('latest'));

        expect(written.id, 'file-2', reason: 'the newest copy is the one kept');
        expect(server.files, hasLength(1));
        expect(utf8.decode(server.files.single.content), 'latest');
      });

      // The bytes are already stored by then. Reporting a failure would tell
      // the caller the backup did not happen when it did — and a 404 from the
      // cleanup would even surface as BackupNotFoundException.
      test('reports success when a stale copy can no longer be deleted', () async {
        server.undeletable.add('file-1');

        final written = await store.write('a.json', _bytes('latest'));

        expect(written.id, 'file-2');
        expect(utf8.decode(await store.read('a.json')), 'latest');
      });

      test('still fails a write the server rejects outright', () async {
        server.failWith = 500;

        await expectLater(
          store.write('a.json', _bytes('latest')),
          throwsA(isA<CloudStorageException>()),
        );
      });

      test('delete removes every copy', () async {
        await store.delete('a.json');

        expect(server.files, isEmpty);
      });
    });

    test('escapes quotes in Drive queries', () async {
      await expectLater(store.read("it's.json"), throwsA(isA<BackupNotFoundException>()));

      expect(
        server.listRequests.last.queryParameters['q'],
        r"name = 'it\'s.json' and trashed = false",
      );
    });

    test('refreshes a rejected token once and retries', () async {
      await store.write('a.json', _bytes('a'));
      server.validTokens = <String>{'token-2'};

      expect(utf8.decode(await store.read('a.json')), 'a');
      expect(tokens.invalidated, <String>['token-1']);
      expect(server.lastAuthorization, 'Bearer token-2');
    });

    // Concurrent requests share one token. The second request's 401 is made to
    // arrive after the first has already replaced that token, so the late
    // handler must recognise the replacement instead of discarding it — which
    // would leave the next request with no token at all.
    test('a late 401 does not discard the replacement token', () async {
      await store.write('a.json', _bytes('a'));
      await store.write('b.json', _bytes('b'));
      server
        ..validTokens = <String>{'token-2'}
        ..firstListDelay['b.json'] = const Duration(milliseconds: 50);

      final contents = await Future.wait(<Future<String>>[
        store.read('a.json').then(utf8.decode),
        store.read('b.json').then(utf8.decode),
      ]);

      expect(contents, <String>['a', 'b']);
      expect(tokens.invalidated, <String>['token-1'], reason: 'only the rejected token is dropped');
      expect(server.lastAuthorization, 'Bearer token-2');
    });

    // While one request is still invalidating the dead token, the provider
    // would hand that same token back. A second request hitting its 401 in
    // that window has to wait for the refresh rather than start its own.
    test('a request that hits 401 mid-refresh waits for the new token', () async {
      await store.write('a.json', _bytes('a'));
      await store.write('b.json', _bytes('b'));
      server
        ..validTokens = <String>{'token-2'}
        ..firstListDelay['b.json'] = const Duration(milliseconds: 20);
      tokens.invalidateDelay = const Duration(milliseconds: 80);

      final contents = await Future.wait(<Future<String>>[
        store.read('a.json').then(utf8.decode),
        store.read('b.json').then(utf8.decode),
      ]);

      expect(contents, <String>['a', 'b']);
      expect(tokens.invalidated, <String>['token-1']);
    });

    test('requires interactive authorization when no silent token exists', () async {
      tokens.silentToken = null;

      expect(await store.connect(), isFalse);
      await expectLater(store.list(), throwsA(isA<CloudAuthenticationException>()));

      expect(await store.connect(interactive: true), isTrue);
      expect(await store.list(), isEmpty);
    });

    test('maps server failures to package exceptions', () async {
      server.failWith = 500;

      await expectLater(store.list(), throwsA(isA<CloudStorageException>()));
    });

    test('times out a request that never answers', () async {
      store = GoogleDriveBackupStore(
        tokenProvider: tokens,
        httpClient: MockClient((_) => Completer<http.Response>().future),
        requestTimeout: const Duration(milliseconds: 50),
      );

      await expectLater(store.list(), throwsA(isA<CloudStorageException>()));
    });

    test('maps TLS failures to CloudStorageException', () async {
      store = GoogleDriveBackupStore(
        tokenProvider: tokens,
        httpClient: MockClient((_) => throw const HandshakeException('bad certificate')),
      );

      await expectLater(store.list(), throwsA(isA<CloudStorageException>()));
    });

    // Same contract as iCloud: a name that is not a plain file name is a
    // programming error on both backends, not a missing file.
    test('refuses a file name that is not a plain file name', () async {
      await store.write('a.json', _bytes('keep me'));
      for (final fileName in <String>['', '   ', 'nested/a.json', '.a.json']) {
        await expectLater(store.delete(fileName), throwsA(isA<ArgumentError>()));
        await expectLater(store.read(fileName), throwsA(isA<ArgumentError>()));
        await expectLater(store.write(fileName, Uint8List(1)), throwsA(isA<ArgumentError>()));
      }
      expect(server.files.map((file) => file.name), <String>['a.json']);
      expect(utf8.decode(server.files.single.content), 'keep me');
    });

    // Drive's reported size is authoritative here (unlike iCloud's eventually
    // consistent metadata), so an oversized object is refused without spending
    // the download.
    test('refuses an object Drive reports as oversized before downloading', () async {
      server.seed('big.json', 'x', DateTime.utc(2026), reportedSize: 100);

      await expectLater(store.read('big.json'), throwsA(isA<BackupFormatException>()));
      expect(server.downloads, 0, reason: 'refused before spending the download');
    });

    // The reported size is a hint, not a promise: the stream is counted too.
    test('refuses an object whose size Drive understates', () async {
      server.seed('big.json', 'x' * 65, DateTime.utc(2026), reportedSize: 1);

      await expectLater(store.read('big.json'), throwsA(isA<BackupFormatException>()));
    });

    test('rejects oversized objects before uploading', () async {
      await expectLater(
        store.write('big.json', Uint8List(65)),
        throwsA(isA<BackupFormatException>()),
      );
      expect(server.files, isEmpty);
    });

    test('disconnect invalidates the token and signs out', () async {
      await store.connect();
      await store.disconnect();

      expect(tokens.invalidated, <String>['token-1']);
      expect(tokens.signedOut, isTrue);
    });
  });
}

Uint8List _bytes(String value) => Uint8List.fromList(utf8.encode(value));

class _FakeTokenProvider implements GoogleDriveTokenProvider {
  String? silentToken = 'token-1';
  final List<String> invalidated = <String>[];
  bool signedOut = false;

  @override
  Future<String?> accessToken({required bool interactive}) async {
    if (silentToken == null && interactive) {
      silentToken = 'token-1';
    }
    return silentToken;
  }

  /// Makes invalidation slow, so another request can arrive mid-refresh.
  Duration invalidateDelay = Duration.zero;

  @override
  Future<void> invalidate(String accessToken) async {
    invalidated.add(accessToken);
    if (invalidateDelay > Duration.zero) {
      await Future<void>.delayed(invalidateDelay);
    }
    silentToken = 'token-2';
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _DriveFile {
  _DriveFile({required this.id, required this.name, required this.parents, required this.content});

  final String id;
  final String name;
  final List<String> parents;
  Uint8List content;
  DateTime modifiedTime = DateTime.now().toUtc();

  /// Size the server claims, when it differs from what it actually serves.
  int? reportedSize;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'size': '${reportedSize ?? content.length}',
    'createdTime': modifiedTime.toIso8601String(),
    'modifiedTime': modifiedTime.toIso8601String(),
  };
}

/// Minimal in-memory implementation of the Drive v3 endpoints the store uses.
class _FakeDriveServer {
  final List<_DriveFile> files = <_DriveFile>[];
  final List<Uri> listRequests = <Uri>[];

  /// Number of media downloads served.
  int downloads = 0;

  /// Set to false to model a provider that ignores `orderBy`.
  bool honorOrderBy = true;
  Set<String> validTokens = <String>{'token-1'};
  String? lastAuthorization;
  int? failWith;
  int _nextId = 1;

  /// Delay before answering the first list request for a given file name, so
  /// one request's 401 can be made to arrive after another request has already
  /// refreshed the token.
  final Map<String, Duration> firstListDelay = <String, Duration>{};

  /// Ids whose DELETE fails with [deleteFailureStatus].
  final Set<String> undeletable = <String>{};
  int deleteFailureStatus = 404;

  /// Adds a file directly, bypassing the store, so duplicate names can exist.
  _DriveFile seed(String name, String content, DateTime modifiedTime, {int? reportedSize}) {
    final file =
        _DriveFile(
            id: 'file-${_nextId++}',
            name: name,
            parents: const <String>['appDataFolder'],
            content: Uint8List.fromList(utf8.encode(content)),
          )
          ..modifiedTime = modifiedTime
          ..reportedSize = reportedSize;
    files.add(file);
    return file;
  }

  Future<http.Response> handle(http.Request request) async {
    // Before the authorization check, so a 401 can be made to arrive late.
    for (final name in firstListDelay.keys.toList()) {
      if (request.url.queryParameters['q']?.contains("'$name'") ?? false) {
        await Future<void>.delayed(firstListDelay.remove(name)!);
      }
    }
    lastAuthorization = request.headers['authorization'];
    if (!validTokens.any((token) => lastAuthorization == 'Bearer $token')) {
      return _error(401, 'authError');
    }
    if (failWith case final status?) {
      return _error(status, 'backendError');
    }

    final path = request.url.path;
    final id = path.split('/').last;
    switch (request.method) {
      case 'GET' when path == '/drive/v3/files':
        listRequests.add(request.url);

        final match = RegExp(
          r"^name = '((?:[^'\\]|\\.)*)' and trashed = false$",
        ).firstMatch(request.url.queryParameters['q'] ?? '');
        final name = match?.group(1)?.replaceAllMapped(RegExp(r'\\(.)'), (m) => m.group(1)!);
        final matches = files.where((file) => name == null || file.name == name).toList();
        // Only honor the documented ordering when the caller actually asked for
        // it, so dropping `orderBy` in the store shows up as a failing test.
        if (honorOrderBy && request.url.queryParameters['orderBy'] == 'modifiedTime desc') {
          matches.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
        }
        return _json(<String, Object?>{'files': matches.map((file) => file.toJson()).toList()});
      case 'GET' when request.url.queryParameters['alt'] == 'media':
        downloads += 1;
        final file = _find(id);
        return file == null
            ? _error(404, 'notFound')
            : http.Response.bytes(file.content, 200, headers: {'content-type': 'application/json'});
      case 'POST' when path == '/upload/drive/v3/files':
        final (metadata, content) = _parseMultipart(request.body);
        final file = _DriveFile(
          id: 'file-${_nextId++}',
          name: metadata['name']! as String,
          parents: (metadata['parents']! as List<Object?>).cast<String>(),
          content: content,
        );
        files.add(file);
        return _json(file.toJson());
      case 'PATCH' when path.startsWith('/upload/drive/v3/files/'):
        final file = _find(id);
        if (file == null) {
          return _error(404, 'notFound');
        }
        file
          ..content = _parseMultipart(request.body).$2
          ..modifiedTime = DateTime.now().toUtc();
        return _json(file.toJson());
      case 'DELETE' when undeletable.contains(id):
        return _error(deleteFailureStatus, 'notFound');
      case 'DELETE':
        final file = _find(id);
        if (file == null) {
          return _error(404, 'notFound');
        }
        files.remove(file);
        return http.Response('', 204);
    }
    return _error(400, 'badRequest');
  }

  _DriveFile? _find(String id) {
    for (final file in files) {
      if (file.id == id) return file;
    }
    return null;
  }

  static (Map<String, Object?>, Uint8List) _parseMultipart(String body) {
    final parts = body.split('--314159265358979323846');
    String content(String part) => part.substring(part.indexOf('\r\n\r\n') + 4).trim();
    return (jsonDecode(content(parts[1])) as Map<String, Object?>, base64Decode(content(parts[2])));
  }

  static http.Response _json(Map<String, Object?> body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  static http.Response _error(int status, String reason) => http.Response(
    jsonEncode(<String, Object?>{
      'error': <String, Object?>{
        'code': status,
        'message': reason,
        'errors': <Object?>[
          <String, Object?>{'reason': reason, 'message': reason},
        ],
      },
    }),
    status,
    headers: {'content-type': 'application/json'},
  );
}
