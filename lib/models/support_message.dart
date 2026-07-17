class SupportMessage {
  final String id;
  final String ticketId;
  final String authorRole;
  final String body;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.authorRole,
    required this.body,
    required this.createdAt,
  });

  bool get isFromAdmin => authorRole == 'admin';
  bool get isFromUser => authorRole == 'user';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      authorRole: json['author_role'] as String? ?? 'user',
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
