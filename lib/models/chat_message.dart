class ChatMessage {
  final String id;
  final String conversationId;
  final String? senderId;
  final String body;
  final String messageType;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.body,
    this.messageType = 'user',
    required this.createdAt,
  });

  bool get isSystem => messageType == 'system';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String?,
      body: json['body'] as String,
      messageType: json['message_type'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
