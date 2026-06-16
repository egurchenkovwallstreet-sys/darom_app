class DealInfo {
  final String id;
  final String counterpartyName;
  final String counterpartyRole;

  const DealInfo({
    required this.id,
    required this.counterpartyName,
    required this.counterpartyRole,
  });

  factory DealInfo.fromJson(Map<String, dynamic> json) {
    return DealInfo(
      id: json['id'] as String,
      counterpartyName: json['counterparty_name'] as String? ?? 'Пользователь',
      counterpartyRole: json['counterparty_role'] as String? ?? 'recipient',
    );
  }
}
