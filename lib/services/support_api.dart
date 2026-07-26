import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/support_message.dart';
import '../models/support_ticket.dart';
import 'api_config.dart';
import 'auth_headers.dart';
import 'darom_http_client.dart';

class SupportApi {
  SupportApi({http.Client? client}) : _client = client ?? createDaromHttpClient();

  final http.Client _client;

  Future<List<SupportTicket>> fetchMyTickets({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/tickets').replace(
      queryParameters: {'phone': phone},
    );
    final response = await _client
        .get(uri, headers: await authHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw SupportApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => SupportTicket.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchUnreadSummary({required String phone}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/unread-summary').replace(
        queryParameters: {'phone': phone},
      );
      final response = await _client
          .get(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['total_unread'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    return _fetchUnreadTotalFromList(phone);
  }

  Future<int> fetchAdminUnreadSummary() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/admin/unread-summary');
      final response = await _client
          .get(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['total_unread'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    try {
      final tickets = await fetchAdminTickets();
      return tickets.fold<int>(0, (sum, ticket) => sum + ticket.unreadForAdmin);
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchUnreadTotalFromList(String phone) async {
    try {
      final tickets = await fetchMyTickets(phone: phone);
      return tickets.fold<int>(0, (sum, ticket) => sum + ticket.unreadForUser);
    } catch (_) {
      return 0;
    }
  }

  Future<SupportTicket> createTicket({
    required String phone,
    String? subject,
    required String body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/tickets');
    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({
            'phone': phone,
            if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
            'body': body,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw SupportApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SupportTicket.fromJson(data['ticket'] as Map<String, dynamic>);
  }

  Future<SupportThreadData> fetchThread({
    required String phone,
    required String ticketId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/tickets/$ticketId/messages')
        .replace(queryParameters: {'phone': phone});
    final response = await _client
        .get(uri, headers: await authHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw SupportApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SupportThreadData(
      ticket: SupportTicket.fromJson(data['ticket'] as Map<String, dynamic>),
      messages: (data['messages'] as List<dynamic>? ?? [])
          .map((m) => SupportMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<SupportMessage> sendUserMessage({
    required String phone,
    required String ticketId,
    required String body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/tickets/$ticketId/messages');
    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone, 'body': body}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw SupportApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SupportMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<void> markTicketRead({
    required String phone,
    required String ticketId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/tickets/$ticketId/read');
    await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<void> markAdminTicketRead({required String ticketId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/admin/tickets/$ticketId/read');
    await _client
        .post(uri, headers: await jsonAuthHeaders(), body: jsonEncode({}))
        .timeout(const Duration(seconds: 10));
  }

  Future<List<SupportTicket>> fetchAdminTickets() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/admin/tickets');
    final response = await _client
        .get(uri, headers: await authHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw SupportApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? [])
        .map((item) => SupportTicket.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SupportThreadData> fetchAdminThread({required String ticketId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/admin/tickets/$ticketId/messages');
    final response = await _client
        .get(uri, headers: await authHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw SupportApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SupportThreadData(
      ticket: SupportTicket.fromJson(data['ticket'] as Map<String, dynamic>),
      messages: (data['messages'] as List<dynamic>? ?? [])
          .map((m) => SupportMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<SupportMessage> sendAdminMessage({
    required String ticketId,
    required String body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/admin/tickets/$ticketId/messages');
    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'body': body}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw SupportApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SupportMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<SupportTicket> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/admin/tickets/$ticketId');
    final response = await _client
        .patch(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw SupportApiException(_errorFrom(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SupportTicket.fromJson(data['ticket'] as Map<String, dynamic>);
  }

  String _errorFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Ошибка поддержки';
    } catch (_) {
      return 'Ошибка поддержки (${response.statusCode})';
    }
  }

  void dispose() => _client.close();
}

class SupportThreadData {
  final SupportTicket ticket;
  final List<SupportMessage> messages;

  const SupportThreadData({required this.ticket, required this.messages});
}

class SupportApiException implements Exception {
  final String message;
  const SupportApiException(this.message);

  @override
  String toString() => message;
}
