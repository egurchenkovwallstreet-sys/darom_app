import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Регистрирует SW Firebase до getToken — иначе push на Web часто молча не работает.
Future<void> ensureMessagingServiceWorker() async {
  final swContainer = web.window.navigator.serviceWorker;
  if (swContainer == null) return;

  try {
    await swContainer.register('/firebase-messaging-sw.js'.toJS).toDart;
  } catch (_) {
    // Конфликт с flutter_service_worker — Firebase повторит getToken сам.
  }
}
