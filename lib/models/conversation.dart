class Conversation {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingStatus;
  final String donorId;
  final String recipientId;
  final String counterpartyName;
  final bool isDonor;
  final bool showReserveButton;
  final bool canReserve;
  final bool showDonorActions;
  final bool isReservedByMe;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingStatus,
    required this.donorId,
    required this.recipientId,
    required this.counterpartyName,
    required this.isDonor,
    this.showReserveButton = false,
    this.canReserve = false,
    this.showDonorActions = false,
    this.isReservedByMe = false,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final showReserveButton = json['show_reserve_button'] as bool? ??
        _legacyShowReserveButton(json);
    return Conversation(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      listingTitle: json['listing_title'] as String,
      listingStatus: json['listing_status'] as String? ?? 'active',
      donorId: json['donor_id'] as String,
      recipientId: json['recipient_id'] as String,
      counterpartyName: json['counterparty_name'] as String,
      isDonor: json['is_donor'] as bool? ?? false,
      showReserveButton: showReserveButton,
      canReserve: json['can_reserve'] as bool? ?? false,
      showDonorActions: json['show_donor_actions'] as bool? ?? false,
      isReservedByMe: json['is_reserved_by_me'] as bool? ?? false,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: _parseDate(json['last_message_at']),
      unreadCount: _parseInt(json['unread_count']),
    );
  }

  static bool _legacyShowReserveButton(Map<String, dynamic> json) {
    final isDonor = json['is_donor'] as bool? ?? false;
    final status = json['listing_status'] as String? ?? 'active';
    return !isDonor && status == 'active';
  }

  Conversation copyWith({
    String? listingStatus,
    bool? showReserveButton,
    bool? canReserve,
    bool? showDonorActions,
    bool? isReservedByMe,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
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
      showReserveButton: showReserveButton ?? this.showReserveButton,
      canReserve: canReserve ?? this.canReserve,
      showDonorActions: showDonorActions ?? this.showDonorActions,
      isReservedByMe: isReservedByMe ?? this.isReservedByMe,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
