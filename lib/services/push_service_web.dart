import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('daromFetchFcmToken')
external JSPromise<JSString> _daromFetchFcmTokenExternal(JSString vapidKey);

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

  try {
    final token = await _daromFetchFcmTokenExternal(vapidKey.toJS).toDart;
    final value = token.toDart;
    return value.isEmpty ? null : value;
  } catch (error) {
    rethrow;
  }
}
