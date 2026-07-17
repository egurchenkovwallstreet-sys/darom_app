class SupportTicket {
  final String id;
  final String? subject;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? userName;
  final String? userPhone;
  final int unreadForUser;
  final int unreadForAdmin;

  const SupportTicket({
    required this.id,
    this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.userName,
    this.userPhone,
    this.unreadForUser = 0,
    this.unreadForAdmin = 0,
  });

  bool get isClosed => status == 'closed';

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'Новое';
      case 'in_progress':
        return 'В работе';
      case 'closed':
        return 'Закрыто';
      default:
        return status;
    }
  }

  String get displayTitle {
    final trimmed = subject?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return 'Обращение без темы';
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      subject: json['subject'] as String?,
      status: json['status'] as String? ?? 'new',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      unreadForUser: (json['unread_for_user'] as num?)?.toInt() ?? 0,
      unreadForAdmin: (json['unread_for_admin'] as num?)?.toInt() ?? 0,
    );
  }
}
