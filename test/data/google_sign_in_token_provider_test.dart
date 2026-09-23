import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  late _FakeGoogleSignInPlatform platform;

  setUp(() {
    platform = _FakeGoogleSignInPlatform();
    GoogleSignInPlatform.instance = platform;
  });

  // Initialization is process-wide, so this test must run first.
  test('initializes once per process and retries after a failure', () async {
    platform.initError = PlatformException(code: 'channel-error');

    await expectLater(
      GoogleSignInTokenProvider().accessToken(interactive: false),
      throwsA(isA<CloudAuthenticationException>()),
    );
    platform.initError = null;
    expect(await GoogleSignInTokenProvider().accessToken(interactive: false), 'token');
    expect(await GoogleSignInTokenProvider().accessToken(interactive: false), 'token');

    expect(platform.initCalls, 2);
  });

  test('never prompts when not interactive', () async {
    platform.grantedWithoutPrompt = false;

    expect(await GoogleSignInTokenProvider().accessToken(interactive: false), isNull);
    expect(platform.prompts, 0);
  });

  test('prompts for drive.appdata when interactive', () async {
    platform.grantedWithoutPrompt = false;

    expect(await GoogleSignInTokenProvider().accessToken(interactive: true), 'token');
    expect(platform.prompts, 1);
    expect(platform.lastScopes, <String>['https://www.googleapis.com/auth/drive.appdata']);
  });

  test('treats a cancelled Android consent screen as no token', () async {
    platform
      ..grantedWithoutPrompt = false
      ..promptError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'SDK reported an exception: 16: ',
      );

    expect(await GoogleSignInTokenProvider().accessToken(interactive: true), isNull);
  });

  test('reports other authorization failures', () async {
    platform
      ..grantedWithoutPrompt = false
      ..promptError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'SDK reported an exception: 10: ',
      );

    await expectLater(
      GoogleSignInTokenProvider().accessToken(interactive: true),
      throwsA(isA<CloudAuthenticationException>()),
    );
  });

  test('wraps platform channel errors', () async {
    platform.channelError = PlatformException(code: 'channel-error');

    await expectLater(
      GoogleSignInTokenProvider().accessToken(interactive: false),
      throwsA(isA<CloudAuthenticationException>()),
    );
  });

  test('ignores invalidation failures and wraps sign-out failures', () async {
    platform.clearError = PlatformException(code: 'channel-error');
    platform.signOutError = PlatformException(code: 'channel-error');
    final provider = GoogleSignInTokenProvider();

    await provider.invalidate('token');
    await expectLater(provider.signOut(), throwsA(isA<CloudAuthenticationException>()));
  });
}

class _FakeGoogleSignInPlatform extends GoogleSignInPlatform with MockPlatformInterfaceMixin {
  int initCalls = 0;
  int prompts = 0;
  bool grantedWithoutPrompt = true;
  List<String>? lastScopes;
  Object? initError;
  Object? promptError;
  Object? channelError;
  Object? clearError;
  Object? signOutError;

  @override
  Future<void> init(InitParameters params) async {
    initCalls += 1;
    if (initError case final error?) {
      throw error;
    }
  }

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async {
    lastScopes = params.request.scopes;
    if (channelError case final error?) {
      throw error;
    }
    if (params.request.promptIfUnauthorized) {
      prompts += 1;
      if (promptError case final error?) {
        throw error;
      }
    } else if (!grantedWithoutPrompt) {
      return null;
    }
    return const ClientAuthorizationTokenData(accessToken: 'token');
  }

  @override
  Future<void> clearAuthorizationToken(ClearAuthorizationTokenParams params) async {
    if (clearError case final error?) {
      throw error;
    }
  }

  @override
  Future<void> signOut(SignOutParams params) async {
    if (signOutError case final error?) {
      throw error;
    }
  }

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) => null;

  @override
  bool supportsAuthenticate() => false;

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) =>
      throw UnimplementedError();

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) => throw UnimplementedError();

  @override
  Future<void> disconnect(DisconnectParams params) async {}
}
