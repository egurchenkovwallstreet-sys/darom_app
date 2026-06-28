import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

@JS('daromFetchFcmToken')
external JSPromise<JSAny?> _daromFetchFcmTokenExternal(JSString vapidKey);

String? _readJsString(JSAny? value) {
  if (value == null) return null;
  if (value.isA<JSString>()) {
    return (value as JSString).toDart;
  }
  final dartValue = value.dartify();
  if (dartValue is String) return dartValue;
  return dartValue?.toString();
}

/// Регистрирует SW Firebase до getToken — иначе push на Web часто молча не работает.
Future<void> ensureMessagingServiceWorker() async {
  final swContainer = web.window.navigator.serviceWorker;
  if (swContainer == null) return;

  try {
    await swContainer.register('/firebase-messaging-sw.js'.toJS).toDart;
    await swContainer.ready.toDart;
  } catch (_) {
    // Flutter SW может уже занять scope — push_helper передаёт registration в getToken.
  }
}

Future<String?> getWebFcmToken(String vapidKey) async {
  if (vapidKey.isEmpty) return null;

  final result = await _daromFetchFcmTokenExternal(vapidKey.toJS).toDart;
  final value = _readJsString(result);
  if (value == null || value.isEmpty) return null;
  return value;
}
