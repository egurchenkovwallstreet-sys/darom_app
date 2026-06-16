import 'package:flutter/foundation.dart';

/// Адрес backend-сервера.
///
/// **Разработка на ПК:** [remoteHost] = IP Timeweb → API на сервере.
/// **Сайт на сервере (этап B):** открываете http://IP/ — API автоматически на :3000.
/// **Локально без сервера:** [remoteHost] = '' → localhost:3000.
class ApiConfig {
  ApiConfig._();

  static const int port = 3000;

  /// IP Timeweb. Пустая строка = только localhost (ПК без удалённого API).
  static const String remoteHost = '5.129.243.246';

  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      final host = uri.host;
      if (host != 'localhost' && host != '127.0.0.1') {
        // Сайт открыт с сервера (не localhost) — API на том же IP, порт 3000.
        // После nginx proxy /api → можно убрать :3000 (см. deploy/nginx-darom.conf).
        final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
        return '$scheme://$host:$port';
      }
    }

    if (remoteHost.isNotEmpty) {
      return 'http://$remoteHost:$port';
    }

    return 'http://localhost:$port';
  }
}
