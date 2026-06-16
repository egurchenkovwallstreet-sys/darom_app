class Conversation {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingStatus;
  final String donorId;
  final String recipientId;
  final String counterpartyName;
  final bool isDonor;
  final bool canReserve;
  final bool isReservedByMe;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingStatus,
    required this.donorId,
    required this.recipientId,
    required this.counterpartyName,
    required this.isDonor,
    this.canReserve = false,
    this.isReservedByMe = false,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      listingTitle: json['listing_title'] as String,
      listingStatus: json['listing_status'] as String? ?? 'active',
      donorId: json['donor_id'] as String,
      recipientId: json['recipient_id'] as String,
      counterpartyName: json['counterparty_name'] as String,
      isDonor: json['is_donor'] as bool? ?? false,
      canReserve: json['can_reserve'] as bool? ?? false,
      isReservedByMe: json['is_reserved_by_me'] as bool? ?? false,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: _parseDate(json['last_message_at']),
    );
  }

  Conversation copyWith({
    String? listingStatus,
    bool? canReserve,
    bool? isReservedByMe,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return Conversation(
      id: id,
      listingId: listingId,
      listingTitle: listingTitle,
      listingStatus: listingStatus ?? this.listingStatus,
      donorId: donorId,
      recipientId: recipientId,
      counterpartyName: counterpartyName,
      isDonor: isDonor,
      canReserve: canReserve ?? this.canReserve,
      isReservedByMe: isReservedByMe ?? this.isReservedByMe,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
