class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String donorLevel;
  final double rating;
  final bool isFounder;
  final bool isSuperDonor;
  final int listingLimit;
  final int baseListingLimit;
  final int activeListings;
  final int itemsGiven;
  final int itemsTaken;
  final int pickupLimit;
  final int pickupsUsedThisMonth;
  final int pickupsFreeRemaining;
  final int pickupCredits;
  final String? avatarUrl;
  final bool isPartner;
  final String? partnerPublicCode;

  const User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.donorLevel,
    required this.rating,
    required this.isFounder,
    this.isSuperDonor = false,
    this.listingLimit = 10,
    this.baseListingLimit = 10,
    this.activeListings = 0,
    this.itemsGiven = 0,
    this.itemsTaken = 0,
    this.pickupLimit = 7,
    this.pickupsUsedThisMonth = 0,
    this.pickupsFreeRemaining = 7,
    this.pickupCredits = 0,
    this.avatarUrl,
    this.isPartner = false,
    this.partnerPublicCode,
  });

  int get dealsCount => itemsGiven + itemsTaken;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone'] as String? ?? '',
      donorLevel: json['donor_level'] as String,
      rating: _toDouble(json['rating']),
      isFounder: json['is_founder'] as bool? ?? false,
      isSuperDonor: json['is_super_donor'] as bool? ?? false,
      listingLimit: _toInt(json['listing_limit'], fallback: 10),
      baseListingLimit: _toInt(json['base_listing_limit'], fallback: 10),
      activeListings: _toInt(json['active_listings']),
      itemsGiven: _toInt(json['items_given']),
      itemsTaken: _toInt(json['items_taken']),
      pickupLimit: _toInt(json['pickup_limit'], fallback: 7),
      pickupsUsedThisMonth: _toInt(json['pickups_used_this_month']),
      pickupsFreeRemaining: _toInt(json['pickups_free_remaining'], fallback: 7),
      pickupCredits: _toInt(json['pickup_credits']),
      avatarUrl: json['avatar_url'] as String?,
      isPartner: json['is_partner'] as bool? ?? false,
      partnerPublicCode: json['partner_public_code'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.parse(value.toString());
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }
}
