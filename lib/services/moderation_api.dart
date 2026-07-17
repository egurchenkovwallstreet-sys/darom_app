import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_headers.dart';

class ModerationApi {
  ModerationApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Map<String, dynamic>>> fetchListingReports() async {
    return _fetchList('/api/moderation/reports/listings', 'reports');
  }

  Future<List<Map<String, dynamic>>> fetchChatReports() async {
    return _fetchList('/api/moderation/reports/chats', 'reports');
  }

  Future<void> blockUser({
    required String userId,
    int? days,
    bool permanent = false,
    String? reason,
  }) async {
    await _post('/api/moderation/block/user', {
      'user_id': userId,
      if (days != null) 'days': days,
      'permanent': permanent,
      if (reason != null) 'reason': reason,
    });
  }

  Future<void> blockListing({
    required String listingId,
    int? days,
    bool permanent = false,
    String? reason,
  }) async {
    await _post('/api/moderation/block/listing', {
      'listing_id': listingId,
      if (days != null) 'days': days,
      'permanent': permanent,
      if (reason != null) 'reason': reason,
    });
  }

  Future<List<Map<String, dynamic>>> _fetchList(String path, String key) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client
        .get(uri, headers: await authHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw ModerationApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data[key] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client
        .post(uri, headers: await jsonAuthHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw ModerationApiException(_errorFrom(response));
    }
  }

  String _errorFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Ошибка модерации';
    } catch (_) {
      return 'Ошибка модерации (${response.statusCode})';
    }
  }

  void dispose() => _client.close();
}

class ModerationApiException implements Exception {
  final String message;
  const ModerationApiException(this.message);

  @override
  String toString() => message;
}
