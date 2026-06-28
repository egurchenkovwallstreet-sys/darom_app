import 'package:firebase_messaging/firebase_messaging.dart';

class WebPushRegisterResult {
  const WebPushRegisterResult._({
    required this.ok,
    this.token,
    this.error,
    this.permission,
  });

  final bool ok;
  final String? token;
  final String? error;
  final String? permission;

  factory WebPushRegisterResult.success(String token) {
    return WebPushRegisterResult._(ok: true, token: token);
  }

  factory WebPushRegisterResult.failure(String error, {String? permission}) {
    return WebPushRegisterResult._(ok: false, error: error, permission: permission);
  }
}

Future<void> ensureMessagingServiceWorker() async {}

Future<AuthorizationStatus?> getWebPermissionStatus() async => null;

Future<WebPushRegisterResult> registerWebPush(String vapidKey) async {
  return WebPushRegisterResult.failure('not_web');
}

Future<String?> getWebFcmToken(String vapidKey) async => null;
