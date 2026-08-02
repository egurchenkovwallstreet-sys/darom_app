import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../data/legal_consent.dart';
import '../models/user.dart';
import 'api_config.dart';
import 'auth_headers.dart';
import 'darom_http_client.dart';
import 'partners_api.dart';

class PersonalDataExport {
  const PersonalDataExport({
    required this.exportedAt,
    required this.profile,
    required this.counts,
    required this.note,
  });

  final String exportedAt;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> counts;
  final String note;

  factory PersonalDataExport.fromJson(Map<String, dynamic> json) {
    return PersonalDataExport(
      exportedAt: json['exported_at'] as String? ?? '',
      profile: json['profile'] as Map<String, dynamic>? ?? {},
      counts: json['counts'] as Map<String, dynamic>? ?? {},
      note: json['note'] as String? ?? '',
    );
  }
}

class UsersApi {
  UsersApi({http.Client? client}) : _client = client ?? createDaromHttpClient();

  final http.Client _client;

  Future<RegisterResult> register({
    required String phone,
    required String name,
    String? partnerActivationCode,
    String? referralCode,
    required bool privacyConsent,
    required bool offerAccepted,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users');

    final body = <String, dynamic>{
      'phone': phone,
      'name': name,
      'privacy_consent': privacyConsent,
      'privacy_policy_version': LegalConsent.privacyPolicyVersion,
      'offer_accepted': offerAccepted,
      'offer_version': LegalConsent.offerVersion,
    };
    if (partnerActivationCode != null && partnerActivationCode.isNotEmpty) {
      body['partner_activation_code'] = normalizePartnerCode(partnerActivationCode);
    }
    if (referralCode != null && referralCode.trim().isNotEmpty) {
      body['referral_code'] = normalizePartnerCode(referralCode);
    }

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(decoded['error'] as String? ?? 'Ошибка регистрации');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return RegisterResult(
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      verificationToken: data['verification_token'] as String?,
    );
  }

  Future<User> fetchProfile({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(body['error'] as String? ?? 'Не удалось загрузить профиль');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<PersonalDataExport> fetchPersonalData({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/personal-data').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(body['error'] as String? ?? 'Не удалось загрузить данные');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PersonalDataExport.fromJson(data);
  }

  Future<void> deleteAccount({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/delete-account');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(body['error'] as String? ?? 'Не удалось удалить аккаунт');
    }
  }

  /// Повторное согласие на обработку ПДн (новая редакция политики).
  Future<User> acceptPrivacyConsent({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/privacy-consent');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({
            'phone': phone,
            'privacy_policy_version': LegalConsent.privacyPolicyVersion,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(body['error'] as String? ?? 'Не удалось сохранить согласие');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> activateSuperDonor({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/super-donor');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(body['error'] as String? ?? 'Не удалось подключить тариф');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> activatePickupPack({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/pickup-pack');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(body['error'] as String? ?? 'Не удалось купить пакет заборов');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> uploadAvatar({
    required String phone,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.fields['phone'] = phone;
    request.headers.addAll(await authHeaders());
    request.files.add(
      http.MultipartFile.fromBytes(
        'avatar',
        bytes,
        filename: fileName,
        contentType: _contentTypeForFileName(fileName),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(body['error'] as String? ?? 'Не удалось загрузить аватар');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  MediaType? _contentTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }

  Future<void> registerPushToken({
    required String phone,
    required String token,
    required String platform,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/push-token');
    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({
            'phone': phone,
            'token': token,
            'platform': platform,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw UsersApiException(body['error'] as String? ?? 'Не удалось сохранить push-токен');
    }
  }

  void dispose() => _client.close();
}

class RegisterResult {
  const RegisterResult({
    required this.user,
    this.verificationToken,
  });

  final User user;
  final String? verificationToken;
}

class UsersApiException implements Exception {
  UsersApiException(this.message);

  final String message;

  @override
  String toString() => message;
}