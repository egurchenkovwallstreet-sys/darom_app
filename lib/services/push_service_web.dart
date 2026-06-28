import 'dart:convert';

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:web/web.dart' as web;

import 'push_service_platform.dart';

@JS('daromGetNotificationPermission')
external JSString _daromGetNotificationPermissionExternal();

@JS('daromRegisterWebPush')
external JSPromise<JSAny?> _daromRegisterWebPushExternal(JSString vapidKey);

String? _readJsString(JSAny? value) {
  if (value == null) return null;
  if (value.isA<JSString>()) {
    return (value as JSString).toDart;
  }
  final dartValue = value.dartify();
  if (dartValue is String) return dartValue;
  return dartValue?.toString();
}

WebPushRegisterResult _parseRegisterResponse(String? jsonStr) {
  if (jsonStr == null || jsonStr.isEmpty) {
    return WebPushRegisterResult.failure('empty_response');
  }

  try {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (map['ok'] == true) {
      final token = map['token'] as String? ?? '';
      if (token.isEmpty) {
        return WebPushRegisterResult.failure('empty_fcm_token');
      }
      return WebPushRegisterResult.success(token);
    }

    return WebPushRegisterResult.failure(
      map['error'] as String? ?? 'fcm_unknown_error',
      permission: map['permission'] as String?,
    );
  } catch (error) {
    return WebPushRegisterResult.failure('bad_json_response:$error');
  }
}

AuthorizationStatus? mapWebNotificationPermission(String? permission) {
  switch (permission) {
    case 'granted':
      return AuthorizationStatus.authorized;
    case 'denied':
      return AuthorizationStatus.denied;
    case 'default':
      return AuthorizationStatus.notDetermined;
    default:
      return null;
  }
}

Future<AuthorizationStatus?> getWebPermissionStatus() async {
  final permission = _readJsString(_daromGetNotificationPermissionExternal());
  return mapWebNotificationPermission(permission);
}

Future<WebPushRegisterResult> registerWebPush(String vapidKey) async {
  if (vapidKey.isEmpty) {
    return WebPushRegisterResult.failure('vapid_key_missing');
  }

  final jsResult = await _daromRegisterWebPushExternal(vapidKey.toJS).toDart;
  return _parseRegisterResponse(_readJsString(jsResult));
}

Future<void> ensureMessagingServiceWorker() async {
  final swContainer = web.window.navigator.serviceWorker;
  if (swContainer == null) return;

  try {
    await swContainer.register('/firebase-messaging-sw.js'.toJS).toDart;
    await swContainer.ready.toDart;
  } catch (_) {}
}

Future<String?> getWebFcmToken(String vapidKey) async {
  final result = await registerWebPush(vapidKey);
  if (!result.ok) {
    throw StateError(result.error ?? 'fcm_token_failed');
  }
  return result.token;
}
