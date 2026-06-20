import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class PartnersApi {
  PartnersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> validateActivationCode({required String code}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/partners/validate-activation-code');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': code.trim().toUpperCase()}),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw PartnersApiException(body['error'] as String? ?? 'Неверный код партнёра');
    }
  }

  Future<PartnerStats> fetchStats({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/partners/stats').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw PartnersApiException(body['error'] as String? ?? 'Не удалось загрузить статистику');
    }

    return PartnerStats.fromJson(body);
  }

  void dispose() => _client.close();
}

class PartnerStats {
  const PartnerStats({
    required this.partnerName,
    required this.partnerPublicCode,
    required this.referredUsers,
    required this.paymentsCount,
    required this.totalPaymentsRub,
    required this.payoutRub,
    required this.commissionPercent,
  });

  final String partnerName;
  final String? partnerPublicCode;
  final int referredUsers;
  final int paymentsCount;
  final int totalPaymentsRub;
  final int payoutRub;
  final int commissionPercent;

  factory PartnerStats.fromJson(Map<String, dynamic> json) {
    final partner = json['partner'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};

    return PartnerStats(
      partnerName: partner['name'] as String? ?? '',
      partnerPublicCode: partner['partner_public_code'] as String?,
      referredUsers: (stats['referred_users'] as num?)?.toInt() ?? 0,
      paymentsCount: (stats['payments_count'] as num?)?.toInt() ?? 0,
      totalPaymentsRub: (stats['total_payments_rub'] as num?)?.toInt() ?? 0,
      payoutRub: (stats['payout_rub'] as num?)?.toInt() ?? 0,
      commissionPercent: (stats['commission_percent'] as num?)?.toInt() ?? 30,
    );
  }
}

class PartnersApiException implements Exception {
  PartnersApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
