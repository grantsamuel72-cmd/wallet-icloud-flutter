import 'dart:async';

import 'package:flutter/services.dart';
import 'package:huawei_account/huawei_account.dart';
import 'package:huawei_drive/huawei_drive.dart';
import 'package:huawei_hmsavailability/huawei_hmsavailability.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

/// Owns the HUAWEI ID grant used only for Drive applicationData backups.
class HuaweiCloudSession {
  HuaweiCloudSession()
    : _availability = HmsApiAvailability(),
      _auth = AccountAuthManager.getService(
        (AccountAuthParamsHelper()
              ..setAccessToken()
              ..setId()
              ..setScopeList(
                <Scope>[Scope.openId],
                extraScopeURIs: <String>[scopeDriveAppData],
              ))
            .createParams(),
      );

  final HmsApiAvailability _availability;
  final AccountAuthService _auth;
  String? _accountId;

  String? get accountId => _accountId;

  Future<void> dispose() async {
    await _availability.destroyStreams();
  }

  Future<DriveCredentials?> credentials({required bool interactive}) async {
    var availability = await _availability.isHMSAvailable();
    if (availability != 0) {
      if (!interactive ||
          !await _availability.isUserResolvableError(availability)) {
        throw const CloudUnavailableException('HMS Core 不可用，请安装或更新后重试。');
      }
      final resolution = Completer<AvailabilityEvent?>();
      _availability.setResultListener = (event) {
        if (!resolution.isCompleted) resolution.complete(event);
      };
      try {
        final shown = await _availability.showErrorDialogFragment(
          availability,
          7421,
          true,
        );
        if (!shown) return null;
        final event = await resolution.future.timeout(
          const Duration(minutes: 2),
          onTimeout: () => null,
        );
        if (event != AvailabilityEvent.resultOk) return null;
      } finally {
        _availability.setResultListener = (_) {};
      }
      availability = await _availability.isHMSAvailable();
      if (availability != 0) {
        throw const CloudUnavailableException('HMS Core 仍不可用，请完成安装或更新后重试。');
      }
    }

    AuthAccount account;
    try {
      account = await _auth.silentSignIn();
    } on PlatformException {
      if (!interactive) {
        _accountId = null;
        return null;
      }
      try {
        account = await _auth.signIn();
      } on PlatformException catch (error) {
        _accountId = null;
        if (_isCanceled(error)) return null;
        throw CloudAuthenticationException('华为云授权失败，请重试。', cause: error);
      }
    }
    final id = account.unionId;
    // DriveCredentials in Huawei Drive 5.x still consumes this Account Kit field.
    // ignore: deprecated_member_use
    final token = account.accessToken;
    if (id == null || id.isEmpty || token == null || token.isEmpty) {
      throw const CloudAuthenticationException('华为账号未返回云盘所需的身份或访问令牌。');
    }
    _accountId = id;
    return DriveCredentials(
      unionId: id,
      accessToken: token,
      callback: () async {
        final refreshed = await _auth.silentSignIn();
        if (refreshed.unionId != id) {
          _accountId = null;
          return null;
        }
        // ignore: deprecated_member_use
        return refreshed.accessToken;
      },
    );
  }

  static bool _isCanceled(PlatformException error) {
    final description = '${error.code} ${error.message}'.toLowerCase();
    return description.contains('cancel') || description.contains('2012');
  }
}
