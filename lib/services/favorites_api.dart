import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/listing.dart';
import 'api_config.dart';
import 'auth_headers.dart';

class FavoritesApi {
  FavoritesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Listing>> fetchFavorites({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/favorites').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw FavoritesApiException(body['error'] as String? ?? 'Не удалось загрузить избранное');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Listing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> fetchFavoriteIds({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/favorites/ids').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return {};
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final ids = data['ids'] as List<dynamic>? ?? [];
    return ids.map((id) => id.toString()).toSet();
  }

  Future<void> addFavorite({
    required String phone,
    required String listingId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/favorites/$listingId');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw FavoritesApiException(body['error'] as String? ?? 'Не удалось добавить в избранное');
    }
  }

  Future<void> removeFavorite({
    required String phone,
    required String listingId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/favorites/$listingId').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.delete(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw FavoritesApiException(body['error'] as String? ?? 'Не удалось убрать из избранного');
    }
  }

  void dispose() => _client.close();
}

class FavoritesApiException implements Exception {
  FavoritesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
