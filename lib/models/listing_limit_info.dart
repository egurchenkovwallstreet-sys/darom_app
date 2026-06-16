int _jsonInt(dynamic value, int fallback) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

class SuperDonorUpsell {
  final String title;
  final int priceRub;
  final int durationDays;
  final int extraListings;
  final int newLimit;
  final String description;

  const SuperDonorUpsell({
    required this.title,
    required this.priceRub,
    required this.durationDays,
    required this.extraListings,
    required this.newLimit,
    required this.description,
  });

  factory SuperDonorUpsell.fromJson(Map<String, dynamic> json) {
    return SuperDonorUpsell(
      title: json['title'] as String? ?? 'Супер даритель',
      priceRub: _jsonInt(json['price_rub'], 99),
      durationDays: _jsonInt(json['duration_days'], 30),
      extraListings: _jsonInt(json['extra_listings'], 10),
      newLimit: _jsonInt(json['new_limit'], 20),
      description: json['description'] as String? ?? '',
    );
  }
}

class ListingLimitInfo {
  final String message;
  final int limit;
  final int baseLimit;
  final int activeCount;
  final SuperDonorUpsell? upsell;

  const ListingLimitInfo({
    required this.message,
    required this.limit,
    required this.baseLimit,
    required this.activeCount,
    this.upsell,
  });

  factory ListingLimitInfo.fromJson(Map<String, dynamic> json) {
    final upsellJson = json['upsell'] as Map<String, dynamic>?;

    return ListingLimitInfo(
      message: json['message'] as String? ?? 'Достигнут лимит объявлений',
      limit: _jsonInt(json['limit'], 10),
      baseLimit: _jsonInt(json['base_limit'], 10),
      activeCount: _jsonInt(json['active_count'], 0),
      upsell: upsellJson != null ? SuperDonorUpsell.fromJson(upsellJson) : null,
    );
  }
}
