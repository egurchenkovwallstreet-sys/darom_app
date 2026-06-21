int _jsonInt(dynamic value, int fallback) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

class PickupPackUpsell {
  final String title;
  final int priceRub;
  final int extraPickups;
  final String description;
  final int tier;
  final int tiersTotal;

  const PickupPackUpsell({
    required this.title,
    required this.priceRub,
    required this.extraPickups,
    required this.description,
    this.tier = 1,
    this.tiersTotal = 3,
  });

  factory PickupPackUpsell.fromJson(Map<String, dynamic> json) {
    return PickupPackUpsell(
      title: json['title'] as String? ?? 'Пакет заборов',
      priceRub: _jsonInt(json['price_rub'], 149),
      extraPickups: _jsonInt(json['extra_pickups'], 10),
      description: json['description'] as String? ?? '',
      tier: _jsonInt(json['tier'], 1),
      tiersTotal: _jsonInt(json['tiers_total'], 3),
    );
  }
}

class PickupLimitInfo {
  final String message;
  final int limit;
  final int usedThisMonth;
  final int freeRemaining;
  final int pickupCredits;
  final bool blocked;
  final PickupPackUpsell? upsell;

  const PickupLimitInfo({
    required this.message,
    required this.limit,
    required this.usedThisMonth,
    required this.freeRemaining,
    required this.pickupCredits,
    this.blocked = false,
    this.upsell,
  });

  factory PickupLimitInfo.fromJson(Map<String, dynamic> json) {
    final upsellJson = json['upsell'] as Map<String, dynamic>?;

    return PickupLimitInfo(
      message: json['message'] as String? ?? 'Достигнут лимит заборов',
      limit: _jsonInt(json['limit'], 7),
      usedThisMonth: _jsonInt(json['used_this_month'], 0),
      freeRemaining: _jsonInt(json['free_remaining'], 0),
      pickupCredits: _jsonInt(json['pickup_credits'], 0),
      blocked: json['blocked'] as bool? ?? false,
      upsell: upsellJson != null ? PickupPackUpsell.fromJson(upsellJson) : null,
    );
  }
}
