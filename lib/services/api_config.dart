import 'package:flutter/foundation.dart';

/// Адрес backend-сервера.
/// Chrome / Windows: localhost. Android-эмулятор: замените на http://10.0.2.2:3000
class ApiConfig {
  ApiConfig._();

  static const int port = 3000;

  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:$port';
      }
    }
    return 'http://localhost:$port';
  }
}
