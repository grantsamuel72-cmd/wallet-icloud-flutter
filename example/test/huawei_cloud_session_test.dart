import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huawei_drive/huawei_drive.dart';
import 'package:wallet_cloud_backup_example/data/huawei_cloud_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const availability = MethodChannel(
    'com.huawei.hms.flutter.availability/hms/method',
  );
  const account = MethodChannel('com.huawei.hms.flutter.account/acc');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(availability, null);
    messenger.setMockMethodCallHandler(account, null);
  });

  test(
    'checks HMS, tries silent sign-in, then uses Huawei sign-in with appData scope',
    () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(availability, (call) async {
        if (call.method == 'initStreams') return null;
        if (call.method == 'isHmsAvailable') return 0;
        throw MissingPluginException(call.method);
      });
      messenger.setMockMethodCallHandler(account, (call) async {
        calls.add(call.method);
        final args = (call.arguments as Map<Object?, Object?>)
            .cast<String, dynamic>();
        expect(args['scopeList'], contains(scopeDriveAppData));
        if (call.method == 'silentSignIn') {
          throw PlatformException(code: 'not_signed_in');
        }
        if (call.method == 'signIn') {
          return <String, Object?>{
            'unionId': 'huawei-user',
            'accessToken': 'token',
          };
        }
        throw MissingPluginException(call.method);
      });

      final credentials = await HuaweiCloudSession().credentials(
        interactive: true,
      );
      expect(credentials?.unionId, 'huawei-user');
      expect(calls, <String>['silentSignIn', 'signIn']);
    },
  );

  test(
    'silent failure never launches a login screen during background access',
    () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(
        availability,
        (call) async => call.method == 'isHmsAvailable' ? 0 : null,
      );
      messenger.setMockMethodCallHandler(account, (call) async {
        calls.add(call.method);
        throw PlatformException(code: 'not_signed_in');
      });
      expect(
        await HuaweiCloudSession().credentials(interactive: false),
        isNull,
      );
      expect(calls, <String>['silentSignIn']);
    },
  );
}
