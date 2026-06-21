import 'package:flutter/foundation.dart';

/// Адрес backend-сервера.
///
/// **Разработка на ПК:** [remoteHost] = IP Timeweb → API на сервере.
/// **Сайт на сервере (этап B+):** https://darom-app.online/ — API через nginx /api/.
/// **Локально без сервера:** [remoteHost] = '' → localhost:3000.
class ApiConfig {
  ApiConfig._();

  static const int port = 3000;

  /// IP Timeweb. Пустая строка = только localhost (ПК без удалённого API).
  static const String remoteHost = '5.129.243.246';

  /// Боевой домен (Reg.ru). См. deploy/DOMAIN_HTTPS.md.
  static const String productionDomain = 'darom-app.online';

  static bool _isProductionHost(String host) {
    return host == productionDomain || host == 'www.$productionDomain';
  }

  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      final host = uri.host;
      if (host != 'localhost' && host != '127.0.0.1') {
        final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
        // HTTPS или боевой домен — API через nginx /api/ (без :3000).
        if (scheme == 'https' || _isProductionHost(host)) {
          return '$scheme://$host';
        }
        return '$scheme://$host:$port';
      }
    }

    if (remoteHost.isNotEmpty) {
      return 'http://$remoteHost:$port';
    }

    return 'http://localhost:$port';
  }
}
