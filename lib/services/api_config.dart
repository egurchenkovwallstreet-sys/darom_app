import 'package:flutter/foundation.dart';

/// Адрес backend-сервера.
/// Локально: localhost. Сервер Timeweb: см. [remoteHost].
class ApiConfig {
  ApiConfig._();

  static const int port = 3000;

  /// IP сервera Timeweb. Пустая строка = только localhost (ПК без сервера).
  static const String remoteHost = '5.129.243.246';

  static String get baseUrl {
    if (remoteHost.isNotEmpty) {
      return 'http://$remoteHost:$port';
    }

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:$port';
      }
    }
    return 'http://localhost:$port';
  }
}
