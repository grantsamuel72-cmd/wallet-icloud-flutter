import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:wallet_cloud_backup/src/domain/backup_file_names.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_file.dart';
import 'package:wallet_cloud_backup/src/domain/cloud_backup_store.dart';
import 'package:wallet_cloud_backup/src/domain/exceptions.dart';

/// Configuration for the Google Drive backend.
class GoogleDriveOptions {
  /// Creates Google Drive options.
  const GoogleDriveOptions({
    this.initializeGoogleSignIn = true,
    this.clientId,
    this.serverClientId,
  });

  /// Whether this package calls `GoogleSignIn.instance.initialize`.
  ///
  /// `google_sign_in` must be initialized exactly once per process. Set this
  /// to false when the app already initializes it for its own Google login.
  final bool initializeGoogleSignIn;

  /// Forwarded to `GoogleSignIn.initialize`. Not needed on Android.
  final String? clientId;

  /// Forwarded to `GoogleSignIn.initialize`. Drive authorization on Android
  /// does not need it; pass it only if the app also uses Google sign-in.
  final String? serverClientId;
}

/// Supplies OAuth access tokens for the `drive.appdata` scope.
abstract interface class GoogleDriveTokenProvider {
  /// Returns an access token.
  ///
  /// Returns null when authorization needs UI and [interactive] is false, or
  /// when the user cancels the prompt.
  Future<String?> accessToken({required bool interactive});

  /// Drops [accessToken] from local caches after the API rejected it.
  Future<void> invalidate(String accessToken);

  /// Signs the user out of this app.
  Future<void> signOut();
}

/// Token provider backed by `google_sign_in` authorization.
///
/// It requests only the `drive.appdata` scope and never performs a separate
/// ID-token sign-in, so on Android no `serverClientId` is required.
class GoogleSignInTokenProvider implements GoogleDriveTokenProvider {
  /// Creates a token provider around the process-wide `GoogleSignIn.instance`.
  GoogleSignInTokenProvider({this.options = const GoogleDriveOptions()});

  /// OAuth scopes requested by this package.
  static const List<String> scopes = <String>[drive.DriveApi.driveAppdataScope];

  // GoogleSignIn.instance is process-wide, so its initialization is shared.
  static Future<void>? _initialization;

  // google_sign_in_android reports a cancelled consent screen as unknownError
  // wrapping Play services' ApiException status 16 (CommonStatusCodes.CANCELED).
  static final RegExp _androidCancelledStatus = RegExp(r'exception: 16:');

  /// Sign-in configuration.
  final GoogleDriveOptions options;

  @override
  Future<String?> accessToken({required bool interactive}) async {
    await _ensureInitialized();
    final client = GoogleSignIn.instance.authorizationClient;
    try {
      final authorization =
          await client.authorizationForScopes(scopes) ??
          (interactive ? await client.authorizeScopes(scopes) : null);
      return authorization?.accessToken;
    } on GoogleSignInException catch (error) {
      if (_isCancellation(error)) {
        return null;
      }
      throw CloudAuthenticationException(
        'Google Drive authorization failed (${error.code.name}): ${error.description ?? ''}',
        cause: error,
      );
    } on PlatformException catch (error) {
      throw CloudAuthenticationException(
        'Google Drive authorization failed (${error.code}): ${error.message ?? ''}',
        cause: error,
      );
    }
  }

  static bool _isCancellation(GoogleSignInException error) => switch (error.code) {
    GoogleSignInExceptionCode.canceled ||
    GoogleSignInExceptionCode.interrupted ||
    GoogleSignInExceptionCode.uiUnavailable => true,
    GoogleSignInExceptionCode.unknownError => _androidCancelledStatus.hasMatch(
      error.description ?? '',
    ),
    _ => false,
  };

  @override
  Future<void> invalidate(String accessToken) async {
    await _ensureInitialized();
    try {
      await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(
        accessToken: accessToken,
      );
    } on GoogleSignInException {
      // A fresh token is requested next; a stale cache entry is harmless.
    } on PlatformException {
      // Same as above: invalidation is best effort.
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await GoogleSignIn.instance.signOut();
    } on GoogleSignInException catch (error) {
      throw CloudAuthenticationException('Google sign-out failed.', cause: error);
    } on PlatformException catch (error) {
      throw CloudAuthenticationException('Google sign-out failed.', cause: error);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!options.initializeGoogleSignIn) {
      return;
    }
    final initialization = _initialization ??= GoogleSignIn.instance.initialize(
      clientId: options.clientId,
      serverClientId: options.serverClientId,
    );
    try {
      await initialization;
    } catch (error) {
      // Allow a later call to retry instead of replaying this failure forever.
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      if (error is Exception) {
        throw CloudAuthenticationException('Google Sign-In initialization failed.', cause: error);
      }
      rethrow;
    }
  }
}

/// Google Drive backend restricted to the hidden `appDataFolder` space.
class GoogleDriveBackupStore implements CloudBackupStore {
  /// Creates a Google Drive backend.
  ///
  /// [tokenProvider] and [httpClient] are replaceable for tests.
  GoogleDriveBackupStore({
    GoogleDriveOptions options = const GoogleDriveOptions(),
    GoogleDriveTokenProvider? tokenProvider,
    http.Client? httpClient,
    this.maxObjectSizeInBytes = defaultMaxBackupSizeInBytes,
    this.requestTimeout = const Duration(seconds: 60),
  }) : _tokens = tokenProvider ?? GoogleSignInTokenProvider(options: options) {
    if (maxObjectSizeInBytes <= 0) {
      throw ArgumentError.value(maxObjectSizeInBytes, 'maxObjectSizeInBytes', 'Must be positive.');
    }
    _api = drive.DriveApi(_BearerTokenClient(httpClient ?? http.Client(), () => _accessToken));
  }

  static const String _space = 'appDataFolder';
  static const String _mimeType = 'application/json';
  static const String _fileFields = 'id,name,size,createdTime,modifiedTime';
  static const String _listFields = 'nextPageToken,files($_fileFields)';

  // Access tokens live for about an hour; renew them before they expire.
  static const Duration _tokenRefreshInterval = Duration(minutes: 45);

  final GoogleDriveTokenProvider _tokens;
  late final drive.DriveApi _api;
  String? _accessToken;
  DateTime? _tokenObtainedAt;
  Future<void>? _pendingToken;
  Future<void>? _pendingRefresh;

  /// Maximum object size loaded into memory.
  final int maxObjectSizeInBytes;

  /// Upper bound for one operation (including any paging) before it fails with
  /// [CloudStorageException].
  final Duration requestTimeout;

  @override
  CloudBackupProvider get provider => CloudBackupProvider.googleDrive;

  @override
  Future<bool> connect({bool interactive = false}) async {
    final token = await _tokens.accessToken(interactive: interactive);
    _setToken(token);
    return token != null;
  }

  @override
  Future<void> disconnect() async {
    final token = _accessToken;
    _setToken(null);
    if (token != null) {
      await _tokens.invalidate(token);
    }
    await _tokens.signOut();
  }

  @override
  Future<CloudBackupFile> write(String fileName, Uint8List contents) async {
    assertPlainBackupFileName(fileName);
    _validateSize(contents.length);
    final result = await _run(fileName, () async {
      final media = drive.Media(
        Stream<List<int>>.value(contents),
        contents.length,
        contentType: _mimeType,
      );
      final matches = await _findByName(fileName);
      if (matches.isEmpty) {
        return _api.files.create(
          drive.File(name: fileName, mimeType: _mimeType, parents: const <String>[_space]),
          uploadMedia: media,
          $fields: _fileFields,
        );
      }
      final updated = await _api.files.update(
        drive.File(),
        _requireId(matches.first),
        uploadMedia: media,
        $fields: _fileFields,
      );
      // Two offline devices can each create a file with this name. Keep the one
      // just written and drop the rest, so the wallet has a single backup again
      // and no older ciphertext survives a password change.
      for (final stale in matches.skip(1)) {
        try {
          await _api.files.delete(_requireId(stale));
        } on drive.DetailedApiRequestError catch (error) {
          // The new bytes are stored, so a failed cleanup must not turn this
          // into a failed write; the next write tries again. A 401 still
          // bubbles, so _run can refresh the token and redo the whole request.
          if (error.status == HttpStatus.unauthorized) rethrow;
        } on Exception {
          // A transport failure while cleaning up, for the same reason.
        }
      }
      return updated;
    });
    return _toCloudFile(result);
  }

  @override
  Future<Uint8List> read(String fileName) async {
    assertPlainBackupFileName(fileName);
    return _run(fileName, () async {
      final matches = await _findByName(fileName);
      if (matches.isEmpty) {
        throw BackupNotFoundException(fileName);
      }
      final file = matches.first;
      final reportedSize = int.tryParse(file.size ?? '');
      if (reportedSize != null) {
        _validateSize(reportedSize);
      }
      final response = await _api.files.get(
        _requireId(file),
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (response is! drive.Media) {
        throw const CloudStorageException('Google Drive did not return backup media.');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        builder.add(chunk);
        _validateSize(builder.length);
      }
      return builder.takeBytes();
    });
  }

  @override
  Future<List<CloudBackupFile>> list() async {
    final files = await _run(null, _listFiles);
    final backups = files.map(_toCloudFile).toList()..sort(compareBackupsNewestFirst);
    return List<CloudBackupFile>.unmodifiable(backups);
  }

  @override
  Future<void> delete(String fileName) async {
    assertPlainBackupFileName(fileName);
    return _run(fileName, () async {
      final matches = await _findByName(fileName);
      if (matches.isEmpty) {
        throw BackupNotFoundException(fileName);
      }
      for (final file in matches) {
        await _api.files.delete(_requireId(file));
      }
    });
  }

  /// Runs [request] with a valid token, retrying once after a 401 response.
  Future<T> _run<T>(String? fileName, Future<T> Function() request) async {
    try {
      await _ensureToken();
      final used = _accessToken;
      try {
        return await request().timeout(requestTimeout);
      } on drive.DetailedApiRequestError catch (error) {
        if (error.status != HttpStatus.unauthorized) {
          rethrow;
        }
        // Expired or revoked token: drop it and retry once with a fresh one.
        await _replaceRejectedToken(used);
        return await request().timeout(requestTimeout);
      }
    } on drive.DetailedApiRequestError catch (error) {
      throw _mapApiError(error, fileName);
    } on drive.ApiRequestError catch (error) {
      throw CloudStorageException('Google Drive request failed: ${error.message}', cause: error);
    } on http.ClientException catch (error) {
      throw CloudStorageException('Google Drive network error: ${error.message}', cause: error);
    } on SocketException catch (error) {
      throw CloudStorageException('Google Drive network error: ${error.message}', cause: error);
    } on TlsException catch (error) {
      throw CloudStorageException('Google Drive TLS error: ${error.message}', cause: error);
    } on HttpException catch (error) {
      throw CloudStorageException('Google Drive network error: ${error.message}', cause: error);
    } on FormatException catch (error) {
      throw CloudStorageException('Google Drive returned an invalid response.', cause: error);
    } on TimeoutException catch (error) {
      throw CloudStorageException('Google Drive request timed out.', cause: error);
    }
  }

  Future<void> _ensureToken() {
    final obtainedAt = _tokenObtainedAt;
    if (_accessToken != null &&
        obtainedAt != null &&
        DateTime.now().difference(obtainedAt) < _tokenRefreshInterval) {
      return Future<void>.value();
    }
    // Concurrent operations must share one authorization: without this each
    // would ask google_sign_in for its own token.
    return _pendingToken ??= _obtainToken().whenComplete(() => _pendingToken = null);
  }

  /// Replaces the token a request was rejected for, once per token.
  ///
  /// Concurrent requests share one token, so they reach this together. Only
  /// the one that still sees its own token discards it: without that check a
  /// straggler would throw away the replacement its sibling just obtained and
  /// leave the next request with no token at all.
  Future<void> _replaceRejectedToken(String? used) {
    final pending = _pendingRefresh;
    if (pending != null) {
      // Someone is already replacing this token. Joining them also means not
      // asking for a new one until the old one has finished being invalidated,
      // which would otherwise hand this request the same dead token back.
      return pending;
    }
    if (used == null || _accessToken != used) {
      return _ensureToken();
    }
    return _pendingRefresh = _discardAndRenew(used).whenComplete(() => _pendingRefresh = null);
  }

  Future<void> _discardAndRenew(String rejected) async {
    _setToken(null);
    await _tokens.invalidate(rejected);
    await _ensureToken();
  }

  Future<void> _obtainToken() async {
    if (!await connect()) {
      throw const CloudAuthenticationException(
        'Google Drive authorization is required. '
        'Call connect(interactive: true) from a user action.',
      );
    }
  }

  void _setToken(String? token) {
    _accessToken = token;
    _tokenObtainedAt = token == null ? null : DateTime.now();
  }

  WalletCloudBackupException _mapApiError(drive.DetailedApiRequestError error, String? fileName) {
    const permissionReasons = <String>{'authError', 'insufficientPermissions'};
    final status = error.status;
    if (status == HttpStatus.unauthorized ||
        (status == HttpStatus.forbidden &&
            error.errors.any((detail) => permissionReasons.contains(detail.reason)))) {
      return CloudAuthenticationException(
        'Google Drive rejected the authorization ($status): ${error.message}',
        cause: error,
      );
    }
    if (status == HttpStatus.notFound && fileName != null) {
      return BackupNotFoundException(fileName, cause: error);
    }
    return CloudStorageException(
      'Google Drive request failed ($status): ${error.message}',
      cause: error,
    );
  }

  Future<List<drive.File>> _findByName(String fileName) {
    final escapedName = fileName.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    return _listFiles(query: "name = '$escapedName' and trashed = false");
  }

  Future<List<drive.File>> _listFiles({String? query}) async {
    final result = <drive.File>[];
    String? pageToken;
    do {
      final page = await _api.files.list(
        spaces: _space,
        q: query ?? 'trashed = false',
        orderBy: 'modifiedTime desc',
        pageSize: 100,
        pageToken: pageToken,
        $fields: _listFields,
      );
      result.addAll(page.files ?? const <drive.File>[]);
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return result;
  }

  static String _requireId(drive.File file) {
    final id = file.id;
    if (id == null) {
      throw const CloudStorageException('Google Drive returned a file without an id.');
    }
    return id;
  }

  CloudBackupFile _toCloudFile(drive.File file) {
    final name = file.name;
    if (name == null) {
      throw const CloudStorageException('Google Drive returned incomplete file metadata.');
    }
    return CloudBackupFile(
      id: _requireId(file),
      name: name,
      provider: provider,
      createdAt: file.createdTime,
      modifiedAt: file.modifiedTime,
      sizeInBytes: int.tryParse(file.size ?? ''),
    );
  }

  void _validateSize(int size) {
    if (size > maxObjectSizeInBytes) {
      throw BackupFormatException(
        'Google Drive object is $size bytes, exceeding the $maxObjectSizeInBytes byte limit.',
      );
    }
  }
}

/// Adds the current bearer token to every request.
class _BearerTokenClient extends http.BaseClient {
  _BearerTokenClient(this._inner, this._token);

  final http.Client _inner;
  final String? Function() _token;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final token = _token();
    if (token != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    // A missing token means another operation is mid-refresh. Sending without
    // one yields a 401, which _run retries — better than failing outright.
    return _inner.send(request);
  }
}
