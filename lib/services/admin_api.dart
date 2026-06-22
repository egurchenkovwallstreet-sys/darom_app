import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AdminApi {
  AdminApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<AdminStartLoginResult> startLogin({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/auth/start');
    final response = await _client
        .post(uri, headers: _headers(null), body: jsonEncode({'phone': phone}))
        .timeout(const Duration(seconds: 45));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AdminApiException(body['error'] as String? ?? 'Не удалось начать вход');
    }
    return AdminStartLoginResult.fromJson(body);
  }

  Future<AdminMobileIdPollResult> pollMobileId({
    required String phone,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/auth/mobile-id/poll').replace(
      queryParameters: {'phone': phone, 'session_token': sessionToken},
    );
    final response = await _client
        .get(uri, headers: _headers(null))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AdminApiException(body['error'] as String? ?? 'Ошибка опроса Mobile ID');
    }
    return AdminMobileIdPollResult.fromJson(body);
  }

  Future<void> completeMobileIdPhone({
    required String phone,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/auth/mobile-id/complete');
    final response = await _client
        .post(
          uri,
          headers: _headers(null),
          body: jsonEncode({'phone': phone, 'session_token': sessionToken}),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AdminApiException(body['error'] as String? ?? 'Телефон не подтверждён');
    }
  }

  Future<void> confirmMobileIdOtp({
    required String phone,
    required String sessionToken,
    required String code,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/auth/mobile-id/confirm');
    final response = await _client
        .post(
          uri,
          headers: _headers(null),
          body: jsonEncode({
            'phone': phone,
            'session_token': sessionToken,
            'code': code,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AdminApiException(body['error'] as String? ?? 'Неверный код из SMS');
    }
  }

  Future<AdminVerifyResult> verifyLogin({
    required String phone,
    required String emailCode,
    String? smsCode,
    String? sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/auth/verify');
    final payload = <String, dynamic>{
      'phone': phone,
      'email_code': emailCode,
    };
    if (smsCode != null && smsCode.isNotEmpty) {
      payload['sms_code'] = smsCode;
    }
    if (sessionToken != null && sessionToken.isNotEmpty) {
      payload['session_token'] = sessionToken;
    }

    final response = await _client
        .post(uri, headers: _headers(null), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 45));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AdminApiException(body['error'] as String? ?? 'Неверные коды');
    }
    return AdminVerifyResult.fromJson(body);
  }

  Future<Map<String, dynamic>> fetchMe({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/me');
    final response = await _client
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      throw AdminApiException('Сессия истекла');
    }
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AdminApiException(body['error'] as String? ?? 'Ошибка');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchListingReports({required String token}) async {
    return _fetchList(token, '/api/admin/reports/listings', 'reports');
  }

  Future<List<Map<String, dynamic>>> fetchChatReports({required String token}) async {
    return _fetchList(token, '/api/admin/reports/chats', 'reports');
  }

  Future<Map<String, dynamic>> fetchPlatformStats({
    required String token,
    required String period,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/stats/platform')
        .replace(queryParameters: {'period': period});
    final response = await _client.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw AdminApiException(_errorFrom(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['stats'] as Map<String, dynamic>? ?? {};
  }

  Future<AdminBloggersData> fetchBloggers({
    required String token,
    required String period,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/stats/bloggers')
        .replace(queryParameters: {'period': period});
    final response = await _client.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw AdminApiException(_errorFrom(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bloggers = (data['bloggers'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    return AdminBloggersData(
      nextCode: data['next_code'] as String? ?? '',
      bloggers: bloggers,
    );
  }

  Future<void> blockUser({
    required String token,
    required String userId,
    int? days,
    bool permanent = false,
    String? reason,
  }) async {
    await _postAction(token, '/api/admin/block/user', {
      'user_id': userId,
      if (days != null) 'days': days,
      'permanent': permanent,
      if (reason != null) 'reason': reason,
    });
  }

  Future<void> blockListing({
    required String token,
    required String listingId,
    int? days,
    bool permanent = false,
    String? reason,
  }) async {
    await _postAction(token, '/api/admin/block/listing', {
      'listing_id': listingId,
      if (days != null) 'days': days,
      'permanent': permanent,
      if (reason != null) 'reason': reason,
    });
  }

  Future<void> payPartner({required String token, required String partnerId}) async {
    await _postAction(token, '/api/admin/partner-payout', {'partner_id': partnerId});
  }

  Future<List<Map<String, dynamic>>> _fetchList(
    String token,
    String path,
    String key,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw AdminApiException(_errorFrom(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data[key] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> _postAction(String token, String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client
        .post(uri, headers: _headers(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw AdminApiException(_errorFrom(response));
    }
  }

  String _errorFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Ошибка ${response.statusCode}';
    } catch (_) {
      return 'Error ${response.statusCode}';
    }
  }

  void dispose() => _client.close();
}

class AdminStartLoginResult {
  const AdminStartLoginResult({
    required this.phone,
    required this.emailHint,
    this.mode = 'sms',
    this.sessionToken,
    this.hint,
    this.smsMock = false,
    this.smsDebugCode,
    this.emailMock = true,
    this.emailDebugCode,
  });

  final String phone;
  final String emailHint;
  final String mode;
  final String? sessionToken;
  final String? hint;
  final bool smsMock;
  final String? smsDebugCode;
  final bool emailMock;
  final String? emailDebugCode;

  bool get isMobileId => mode == 'mobile_id';

  factory AdminStartLoginResult.fromJson(Map<String, dynamic> json) {
    return AdminStartLoginResult(
      phone: json['phone'] as String? ?? '',
      emailHint: json['email_hint'] as String? ?? '',
      mode: json['mode'] as String? ?? 'sms',
      sessionToken: json['session_token'] as String?,
      hint: json['hint'] as String?,
      smsMock: json['sms_mock'] as bool? ?? false,
      smsDebugCode: json['sms_debug_code'] as String?,
      emailMock: json['email_mock'] as bool? ?? true,
      emailDebugCode: json['email_debug_code'] as String?,
    );
  }
}

class AdminMobileIdPollResult {
  const AdminMobileIdPollResult({
    required this.needsOtp,
    required this.verified,
    required this.failed,
  });

  final bool needsOtp;
  final bool verified;
  final bool failed;

  factory AdminMobileIdPollResult.fromJson(Map<String, dynamic> json) {
    return AdminMobileIdPollResult(
      needsOtp: json['needs_otp'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
      failed: json['failed'] as bool? ?? false,
    );
  }
}

class AdminVerifyResult {
  const AdminVerifyResult({required this.token, required this.role});

  final String token;
  final String role;

  factory AdminVerifyResult.fromJson(Map<String, dynamic> json) {
    return AdminVerifyResult(
      token: json['token'] as String? ?? '',
      role: json['role'] as String? ?? 'super_admin',
    );
  }
}

class AdminBloggersData {
  const AdminBloggersData({required this.nextCode, required this.bloggers});

  final String nextCode;
  final List<Map<String, dynamic>> bloggers;
}

class AdminApiException implements Exception {
  AdminApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
