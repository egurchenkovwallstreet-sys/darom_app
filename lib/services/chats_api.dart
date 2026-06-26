import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/listing.dart';
import '../models/pickup_limit_info.dart';
import 'api_config.dart';
import 'auth_headers.dart';
import 'listings_api.dart' show PickupLimitException;
import 'real_phone_required.dart';

class ChatsApi {
  ChatsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Conversation>> fetchConversations({required String phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ChatsApiException(body['error'] as String? ?? 'Не удалось загрузить чаты');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchUnreadSummary({required String phone}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats/unread-summary').replace(
        queryParameters: {'phone': phone},
      );

      final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['total_unread'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    return _fetchUnreadTotalFromList(phone);
  }

  Future<int> _fetchUnreadTotalFromList(String phone) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats').replace(
      queryParameters: {'phone': phone},
    );

    final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return 0;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final total = data['total_unread'];
    if (total is num) {
      return total.toInt();
    }

    final items = data['items'] as List<dynamic>? ?? [];
    var sum = 0;
    for (final item in items) {
      final map = item as Map<String, dynamic>;
      sum += (map['unread_count'] as num?)?.toInt() ?? 0;
    }
    return sum;
  }

  Future<void> markConversationRead({
    required String phone,
    required String conversationId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats/$conversationId/read');

    await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<Conversation> startConversation({
    required String phone,
    required String listingId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats/start');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone, 'listing_id': listingId}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ChatsApiException(body['error'] as String? ?? 'Не удалось открыть чат');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Conversation.fromJson(data['conversation'] as Map<String, dynamic>);
  }

  Future<void> reportChat({
    required String phone,
    required String conversationId,
    String? reason,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats/$conversationId/report');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone, if (reason != null) 'reason': reason}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ChatsApiException(body['error'] as String? ?? 'Не удалось отправить жалобу');
    }
  }

  Future<ChatThreadData> fetchMessages({
    required String phone,
    required String conversationId,
    String? afterId,
  }) async {
    final params = {'phone': phone};
    if (afterId != null && afterId.isNotEmpty) {
      params['after_id'] = afterId;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats/$conversationId/messages')
        .replace(queryParameters: params);

    final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ChatsApiException(body['error'] as String? ?? 'Не удалось загрузить сообщения');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = (data['messages'] as List<dynamic>? ?? [])
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();

    return ChatThreadData(
      conversation: Conversation.fromJson(data['conversation'] as Map<String, dynamic>),
      messages: messages,
    );
  }

  Future<SendMessageResult> sendMessage({
    required String phone,
    required String conversationId,
    required String body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats/$conversationId/messages');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone, 'body': body}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 403 && decoded['code'] == 'REAL_PHONE_REQUIRED') {
        throw RealPhoneRequiredException(
          decoded['message'] as String? ?? RealPhoneRequiredException().message,
        );
      }
      throw ChatsApiException(decoded['error'] as String? ?? 'Не удалось отправить сообщение');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SendMessageResult(
      message: ChatMessage.fromJson(data['message'] as Map<String, dynamic>),
      phoneSharingWarning: data['phone_sharing_warning'] as bool? ?? false,
    );
  }

  Future<ChatReserveResult> reserveFromChat({
    required String phone,
    required String conversationId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chats/$conversationId/reserve');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 402) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw PickupLimitException(PickupLimitInfo.fromJson(body));
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ChatsApiException(body['error'] as String? ?? 'Не удалось забронировать');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatReserveResult(
      listing: Listing.fromJson(data['item'] as Map<String, dynamic>),
      conversation: Conversation.fromJson(data['conversation'] as Map<String, dynamic>),
      message: data['message'] as String? ?? 'Забронировано',
    );
  }

  void dispose() => _client.close();
}

class SendMessageResult {
  const SendMessageResult({
    required this.message,
    required this.phoneSharingWarning,
  });

  final ChatMessage message;
  final bool phoneSharingWarning;
}

class ChatThreadData {
  const ChatThreadData({
    required this.conversation,
    required this.messages,
  });

  final Conversation conversation;
  final List<ChatMessage> messages;
}

class ChatReserveResult {
  const ChatReserveResult({
    required this.listing,
    required this.conversation,
    required this.message,
  });

  final Listing listing;
  final Conversation conversation;
  final String message;
}

class ChatsApiException implements Exception {
  ChatsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
