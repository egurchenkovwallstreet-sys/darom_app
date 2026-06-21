import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/deal_info.dart';
import '../models/listing.dart';
import '../models/listing_limit_info.dart';
import '../models/pickup_limit_info.dart';
import 'api_config.dart';
import 'real_phone_required.dart';

export 'real_phone_required.dart' show RealPhoneRequiredException;

class ListingsApi {
  ListingsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Listing>> fetchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius_km': radiusKm.toString(),
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ListingsApiException(
        body['error'] as String? ?? 'Не удалось загрузить объявления на карте',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Listing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Listing>> search({
    required String query,
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/search').replace(
      queryParameters: {
        'q': query,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius_km': radiusKm.toString(),
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ListingsApiException(
        body['error'] as String? ?? 'Не удалось выполнить поиск',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Listing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Listing>> fetchBySubcategory({
    required String category,
    required String subcategory,
    double lat = 55.7558,
    double lng = 37.6173,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings').replace(
      queryParameters: {
        'category': category,
        'subcategory': subcategory,
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ListingsApiException(
        'Сервер ответил кодом ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Listing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, int>> fetchSubcategoryCounts({
    required String category,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/subcategory-counts').replace(
      queryParameters: {'category': category},
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ListingsApiException(
        body['error'] as String? ?? 'Не удалось загрузить счётчики',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['counts'] as Map<String, dynamic>? ?? {};
    return raw.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Future<List<Listing>> fetchMine({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/mine').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ListingsApiException(
        body['error'] as String? ?? 'Не удалось загрузить объявления',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Listing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> create({
    required String phone,
    required String title,
    required String description,
    required String category,
    required String subcategory,
    double lat = 55.7558,
    double lng = 37.6173,
    int photosCount = 0,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'title': title,
            'description': description,
            'category': category,
            'subcategory': subcategory,
            'lat': lat,
            'lng': lng,
            'photos_count': photosCount,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 403 && body['code'] == 'REAL_PHONE_REQUIRED') {
        throw RealPhoneRequiredException(
          body['message'] as String? ?? RealPhoneRequiredException().message,
        );
      }
      if (response.statusCode == 402 && body['code'] == 'LISTING_LIMIT') {
        throw ListingLimitException(ListingLimitInfo.fromJson(body));
      }
      if (response.statusCode == 402 && body['code'] == 'PICKUP_LIMIT') {
        throw PickupLimitException(PickupLimitInfo.fromJson(body));
      }
      throw ListingsApiException(
        body['message'] as String? ?? body['error'] as String? ?? 'Не удалось создать объявление',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Listing.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<Listing> uploadPhoto({
    required String listingId,
    required String phone,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/$listingId/photos');
    final request = http.MultipartRequest('POST', uri);
    request.fields['phone'] = phone;
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: fileName,
        contentType: _contentTypeForFileName(fileName),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ListingsApiException(
        body['error'] as String? ?? 'Не удалось загрузить фото',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Listing.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<Listing> _postAction(String path, String phone) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 402 && body['code'] == 'LISTING_LIMIT') {
        throw ListingLimitException(ListingLimitInfo.fromJson(body));
      }
      if (response.statusCode == 402 && body['code'] == 'PICKUP_LIMIT') {
        throw PickupLimitException(PickupLimitInfo.fromJson(body));
      }
      throw ListingsApiException(
        body['message'] as String? ?? body['error'] as String? ?? 'Ошибка операции',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Listing.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<Listing> reserve({required String listingId, required String phone}) {
    return _postAction('/api/listings/$listingId/reserve', phone);
  }

  Future<Listing> markGiven({required String listingId, required String phone}) async {
    final result = await markGivenWithDeal(listingId: listingId, phone: phone);
    return result.listing;
  }

  Future<GiveResult> markGivenWithDeal({
    required String listingId,
    required String phone,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/$listingId/give');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 402 && body['code'] == 'LISTING_LIMIT') {
        throw ListingLimitException(ListingLimitInfo.fromJson(body));
      }
      if (response.statusCode == 402 && body['code'] == 'PICKUP_LIMIT') {
        throw PickupLimitException(PickupLimitInfo.fromJson(body));
      }
      throw ListingsApiException(
        body['message'] as String? ?? body['error'] as String? ?? 'Ошибка операции',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final dealJson = data['deal'] as Map<String, dynamic>?;

    return GiveResult(
      listing: Listing.fromJson(data['item'] as Map<String, dynamic>),
      deal: dealJson != null ? DealInfo.fromJson(dealJson) : null,
    );
  }

  Future<ReportResult> reportListing({
    required String listingId,
    required String phone,
    String? reason,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/$listingId/report');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            if (reason != null && reason.isNotEmpty) 'reason': reason,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ListingsApiException(body['error'] as String? ?? 'Не удалось отправить жалобу');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ReportResult(
      message: data['message'] as String? ?? 'Жалоба принята',
      reportsCount: (data['reports_count'] as num?)?.toInt() ?? 0,
      hidden: data['hidden'] as bool? ?? false,
    );
  }

  Future<Listing> reactivate({required String listingId, required String phone}) {
    return _postAction('/api/listings/$listingId/reactivate', phone);
  }

  Future<Listing> updateListing({
    required String listingId,
    required String phone,
    required String title,
    required String description,
    required String category,
    required String subcategory,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/$listingId');

    final response = await _client
        .patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'title': title,
            'description': description,
            'category': category,
            'subcategory': subcategory,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ListingsApiException(body['error'] as String? ?? 'Не удалось сохранить изменения');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Listing.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<void> deleteListing({required String listingId, required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings/$listingId/delete');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ListingsApiException(body['error'] as String? ?? 'Не удалось удалить объявление');
    }
  }

  void dispose() => _client.close();
}

MediaType _contentTypeForFileName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}

class GiveResult {
  final Listing listing;
  final DealInfo? deal;

  const GiveResult({required this.listing, this.deal});
}

class ReportResult {
  final String message;
  final int reportsCount;
  final bool hidden;

  const ReportResult({
    required this.message,
    required this.reportsCount,
    required this.hidden,
  });
}

class PickupLimitException implements Exception {
  PickupLimitException(this.limitInfo);

  final PickupLimitInfo limitInfo;

  @override
  String toString() => limitInfo.message;
}

class ListingLimitException implements Exception {
  ListingLimitException(this.limitInfo);

  final ListingLimitInfo limitInfo;

  @override
  String toString() => limitInfo.message;
}

class ListingsApiException implements Exception {
  ListingsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
