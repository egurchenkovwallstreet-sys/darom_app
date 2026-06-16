import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<SendCodeResult> sendCode({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/send-code');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось отправить код');
    }

    return SendCodeResult(
      phone: body['phone'] as String,
      mock: body['mock'] as bool? ?? false,
      debugCode: body['debug_code'] as String?,
    );
  }

  Future<String> verifyCode({required String phone, required String code}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-code');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'code': code}),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Неверный код');
    }

    return body['phone'] as String;
  }

  void dispose() => _client.close();
}

class SendCodeResult {
  final String phone;
  final bool mock;
  final String? debugCode;

  const SendCodeResult({
    required this.phone,
    required this.mock,
    this.debugCode,
  });
}

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
