import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_headers.dart';

class DealsApi {
  DealsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> rateDeal({
    required String dealId,
    required String phone,
    required int score,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/deals/$dealId/rate');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone, 'score': score}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw DealsApiException(body['error'] as String? ?? 'Не удалось отправить оценку');
    }
  }

  void dispose() => _client.close();
}

class DealsApiException implements Exception {
  DealsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
