import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<CheckPhoneResult> checkPhone({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/check-phone');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось проверить номер');
    }

    return CheckPhoneResult.fromJson(body);
  }

  Future<SendCodeResult> sendCode({
    required String phone,
    String purpose = 'register',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/send-code');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'purpose': purpose}),
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

  Future<VerifyCodeResult> verifyCode({
    required String phone,
    required String code,
    String purpose = 'register',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-code');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'code': code, 'purpose': purpose}),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Неверный код');
    }

    return VerifyCodeResult.fromJson(body);
  }

  Future<ActiveVerifySendResult> sendActiveVerifyCode({
    required String accountPhone,
    required String verifyPhone,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/active-verify/send');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': accountPhone,
            'verify_phone': verifyPhone,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось отправить SMS');
    }

    return ActiveVerifySendResult.fromJson(body);
  }

  Future<ActiveVerifyPollResult> pollActiveVerifySession({
    required String accountPhone,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/active-verify/poll').replace(
      queryParameters: {
        'phone': accountPhone,
        'session_token': sessionToken,
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось проверить статус');
    }

    return ActiveVerifyPollResult.fromJson(body);
  }

  Future<ActiveVerifyResult> completeActiveVerifySession({
    required String accountPhone,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/active-verify/complete');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': accountPhone,
            'session_token': sessionToken,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось завершить подтверждение');
    }

    return ActiveVerifyResult(
      phone: body['phone'] as String,
      phoneChanged: body['phone_changed'] as bool? ?? false,
      message: body['message'] as String? ??
          'Теперь вам доступны все функции приложения!',
    );
  }

  Future<ActiveVerifyResult> confirmActiveVerify({
    required String accountPhone,
    required String verifyPhone,
    required String code,
    String? sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/active-verify/confirm');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': accountPhone,
            'verify_phone': verifyPhone,
            'code': code,
            if (sessionToken != null) 'session_token': sessionToken,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Неверный код');
    }

    return ActiveVerifyResult(
      phone: body['phone'] as String,
      phoneChanged: body['phone_changed'] as bool? ?? false,
      message: body['message'] as String? ??
          'Теперь вам доступны все функции приложения!',
    );
  }

  Future<PartnerVerifyResult> sendPartnerVerify({
    required String phone,
    required String partnerActivationCode,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/partner-verify/send');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'partner_activation_code': partnerActivationCode,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось начать подтверждение');
    }

    return PartnerVerifyResult(
      phone: body['phone'] as String,
      partnerActivationCode: body['partner_activation_code'] as String? ?? partnerActivationCode,
      sessionToken: body['session_token'] as String,
      hint: body['hint'] as String?,
    );
  }

  Future<ActiveVerifyPollResult> pollPartnerVerifySession({
    required String phone,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/partner-verify/poll').replace(
      queryParameters: {
        'phone': phone,
        'session_token': sessionToken,
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось проверить статус');
    }

    return ActiveVerifyPollResult.fromJson(body);
  }

  Future<PartnerVerifyCompleteResult> completePartnerVerifySession({
    required String phone,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/partner-verify/complete');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'session_token': sessionToken,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось завершить подтверждение');
    }

    return PartnerVerifyCompleteResult.fromJson(body);
  }

  Future<PartnerVerifyCompleteResult> confirmPartnerVerify({
    required String phone,
    required String code,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/partner-verify/confirm');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'code': code,
            'session_token': sessionToken,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Неверный код');
    }

    return PartnerVerifyCompleteResult.fromJson(body);
  }

  Future<void> setPin({
    required String phone,
    required String pin,
    required String verificationToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/set-pin');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'pin': pin,
            'verification_token': verificationToken,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Не удалось сохранить пароль');
    }
  }

  Future<PinLoginResult> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login-pin');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'pin': pin}),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthApiException(body['error'] as String? ?? 'Неверный пароль');
    }

    final user = body['user'] as Map<String, dynamic>;
    return PinLoginResult(
      id: user['id'] as String,
      phone: user['phone'] as String,
      name: user['name'] as String,
      realPhoneVerified: user['real_phone_verified'] as bool? ?? false,
    );
  }

  void dispose() => _client.close();
}

class CheckPhoneResult {
  const CheckPhoneResult({
    required this.phone,
    required this.registered,
    required this.hasPin,
    required this.needsSms,
    required this.authMethod,
    this.userName,
    this.realPhoneVerified = false,
  });

  final String phone;
  final bool registered;
  final bool hasPin;
  final bool needsSms;
  final String authMethod;
  final String? userName;
  final bool realPhoneVerified;

  factory CheckPhoneResult.fromJson(Map<String, dynamic> json) {
    return CheckPhoneResult(
      phone: json['phone'] as String,
      registered: json['registered'] as bool? ?? false,
      hasPin: json['has_pin'] as bool? ?? false,
      needsSms: json['needs_sms'] as bool? ?? true,
      authMethod: json['auth_method'] as String? ?? 'register',
      userName: json['user_name'] as String?,
      realPhoneVerified: json['real_phone_verified'] as bool? ?? false,
    );
  }
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

class VerifyCodeResult {
  const VerifyCodeResult({
    required this.phone,
    required this.isNewUser,
    required this.hasPin,
    required this.verificationToken,
    this.userName,
    this.realPhoneVerified = false,
  });

  final String phone;
  final bool isNewUser;
  final bool hasPin;
  final String verificationToken;
  final String? userName;
  final bool realPhoneVerified;

  factory VerifyCodeResult.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResult(
      phone: json['phone'] as String,
      isNewUser: json['is_new_user'] as bool? ?? true,
      hasPin: json['has_pin'] as bool? ?? false,
      verificationToken: json['verification_token'] as String,
      userName: json['user_name'] as String?,
      realPhoneVerified: json['real_phone_verified'] as bool? ?? false,
    );
  }
}

class ActiveVerifySendResult {
  const ActiveVerifySendResult({
    required this.phone,
    required this.mode,
    this.mock = false,
    this.debugCode,
    this.sessionToken,
    this.hint,
  });

  final String phone;
  final String mode;
  final bool mock;
  final String? debugCode;
  final String? sessionToken;
  final String? hint;

  bool get isMobileId => mode == 'mobile_id';

  factory ActiveVerifySendResult.fromJson(Map<String, dynamic> json) {
    return ActiveVerifySendResult(
      phone: json['phone'] as String,
      mode: json['mode'] as String? ?? 'sms',
      mock: json['mock'] as bool? ?? false,
      debugCode: json['debug_code'] as String?,
      sessionToken: json['session_token'] as String?,
      hint: json['hint'] as String?,
    );
  }
}

class ActiveVerifyPollResult {
  const ActiveVerifyPollResult({
    required this.status,
    required this.statusLabel,
    required this.needsOtp,
    required this.verified,
    required this.failed,
  });

  final int status;
  final String statusLabel;
  final bool needsOtp;
  final bool verified;
  final bool failed;

  factory ActiveVerifyPollResult.fromJson(Map<String, dynamic> json) {
    return ActiveVerifyPollResult(
      status: (json['status'] as num?)?.toInt() ?? 0,
      statusLabel: json['status_label'] as String? ?? 'pending',
      needsOtp: json['needs_otp'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
      failed: json['failed'] as bool? ?? false,
    );
  }
}

class ActiveVerifyResult {
  const ActiveVerifyResult({
    required this.phone,
    required this.phoneChanged,
    required this.message,
  });

  final String phone;
  final bool phoneChanged;
  final String message;
}

class PartnerVerifyResult {
  const PartnerVerifyResult({
    required this.phone,
    required this.partnerActivationCode,
    required this.sessionToken,
    this.hint,
  });

  final String phone;
  final String partnerActivationCode;
  final String sessionToken;
  final String? hint;
}

class PartnerVerifyCompleteResult {
  const PartnerVerifyCompleteResult({
    required this.phone,
    required this.partnerActivationCode,
    required this.verificationToken,
  });

  final String phone;
  final String partnerActivationCode;
  final String verificationToken;

  factory PartnerVerifyCompleteResult.fromJson(Map<String, dynamic> json) {
    return PartnerVerifyCompleteResult(
      phone: json['phone'] as String,
      partnerActivationCode: json['partner_activation_code'] as String? ?? '',
      verificationToken: json['verification_token'] as String? ?? '',
    );
  }
}

class PinLoginResult {
  const PinLoginResult({
    required this.id,
    required this.phone,
    required this.name,
    this.realPhoneVerified = false,
  });

  final String id;
  final String phone;
  final String name;
  final bool realPhoneVerified;
}

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
