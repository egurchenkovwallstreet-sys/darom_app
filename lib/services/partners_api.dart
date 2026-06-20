import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

String normalizePartnerCode(String code) {
  final digits = code.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final num = int.tryParse(digits);
  if (num == null || num < 1 || num > 1000) return '';
  return num.toString().padLeft(4, '0');
}

class PartnersApi {
  PartnersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> validateActivationCode({required String code}) async {
    final normalized = normalizePartnerCode(code);
    if (normalized.isEmpty) {
      throw PartnersApiException('Код партнёра: 4 цифры от 0001 до 1000');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/partners/validate-activation-code');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': normalized}),
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
    required this.payoutRubMonth,
    required this.payoutRubTotal,
    required this.commissionPercent,
    required this.referralTtlDays,
  });

  final String partnerName;
  final String? partnerPublicCode;
  final int referredUsers;
  final int paymentsCount;
  final int totalPaymentsRub;
  final int payoutRubMonth;
  final int payoutRubTotal;
  final int commissionPercent;
  final int referralTtlDays;

  factory PartnerStats.fromJson(Map<String, dynamic> json) {
    final partner = json['partner'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};

    return PartnerStats(
      partnerName: partner['name'] as String? ?? '',
      partnerPublicCode: partner['partner_public_code'] as String?,
      referredUsers: (stats['referred_users'] as num?)?.toInt() ?? 0,
      paymentsCount: (stats['payments_count'] as num?)?.toInt() ?? 0,
      totalPaymentsRub: (stats['total_payments_rub'] as num?)?.toInt() ?? 0,
      payoutRubMonth: (stats['payout_rub_month'] as num?)?.toInt()
          ?? (stats['payout_rub'] as num?)?.toInt()
          ?? 0,
      payoutRubTotal: (stats['payout_rub_total'] as num?)?.toInt()
          ?? (stats['payout_rub'] as num?)?.toInt()
          ?? 0,
      commissionPercent: (stats['commission_percent'] as num?)?.toInt() ?? 30,
      referralTtlDays: (stats['referral_ttl_days'] as num?)?.toInt() ?? 365,
    );
  }
}

class PartnersApiException implements Exception {
  PartnersApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
