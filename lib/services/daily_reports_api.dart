import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_headers.dart';

class DailyReportSummary {
  final String id;
  final String reportDate;
  final String title;
  final String preview;
  final DateTime? emailSentAt;
  final DateTime createdAt;

  const DailyReportSummary({
    required this.id,
    required this.reportDate,
    required this.title,
    required this.preview,
    this.emailSentAt,
    required this.createdAt,
  });

  factory DailyReportSummary.fromJson(Map<String, dynamic> json) {
    return DailyReportSummary(
      id: json['id'] as String,
      reportDate: json['report_date']?.toString() ?? '',
      title: json['title'] as String? ?? 'Отчёт',
      preview: json['preview'] as String? ?? '',
      emailSentAt: json['email_sent_at'] != null
          ? DateTime.parse(json['email_sent_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DailyReportDetail {
  final String id;
  final String reportDate;
  final String title;
  final String bodyText;
  final DateTime? emailSentAt;
  final DateTime createdAt;

  const DailyReportDetail({
    required this.id,
    required this.reportDate,
    required this.title,
    required this.bodyText,
    this.emailSentAt,
    required this.createdAt,
  });

  factory DailyReportDetail.fromJson(Map<String, dynamic> json) {
    return DailyReportDetail(
      id: json['id'] as String,
      reportDate: json['report_date']?.toString() ?? '',
      title: json['title'] as String? ?? 'Отчёт',
      bodyText: json['body_text'] as String? ?? '',
      emailSentAt: json['email_sent_at'] != null
          ? DateTime.parse(json['email_sent_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DailyReportsApi {
  DailyReportsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<DailyReportSummary>> fetchReports() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/daily-reports');
    final response = await _client
        .get(uri, headers: await authHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw DailyReportsApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? [])
        .map((item) => DailyReportSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DailyReportDetail> fetchReport(String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/daily-reports/$id');
    final response = await _client
        .get(uri, headers: await authHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw DailyReportsApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return DailyReportDetail.fromJson(data['report'] as Map<String, dynamic>);
  }

  Future<void> generateNow({bool force = false}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/daily-reports/generate');
    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'force': force}),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw DailyReportsApiException(_errorFrom(response));
    }
  }

  String _errorFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Ошибка загрузки отчётов';
    } catch (_) {
      return 'Ошибка загрузки отчётов (${response.statusCode})';
    }
  }

  void dispose() => _client.close();
}

class DailyReportsApiException implements Exception {
  final String message;
  const DailyReportsApiException(this.message);

  @override
  String toString() => message;
}
