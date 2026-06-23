class Listing {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String authorName;
  final String authorLevel;
  final double authorRating;
  final bool authorIsFounder;
  final int photosCount;
  final List<String> photoUrls;
  final double distanceKm;
  final String status;
  final DateTime? reservedUntil;
  final double? lat;
  final double? lng;

  const Listing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.authorName,
    required this.authorLevel,
    required this.authorRating,
    this.authorIsFounder = false,
    required this.photosCount,
    this.photoUrls = const [],
    required this.distanceKm,
    this.status = 'active',
    this.reservedUntil,
    this.lat,
    this.lng,
  });

  bool get isReserved => status == 'reserved';
  bool get isActive => status == 'active';

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      authorName: json['author_name'] as String,
      authorLevel: json['author_level'] as String,
      authorRating: _toDouble(json['author_rating']),
      authorIsFounder: json['author_is_founder'] as bool? ?? false,
      photosCount: _toInt(json['photos_count']),
      photoUrls: _parsePhotoUrls(json['photo_urls']),
      distanceKm: _toDouble(json['distance_km']),
      status: json['status'] as String? ?? 'active',
      reservedUntil: _parseDate(json['reserved_until']),
      lat: json['lat'] == null ? null : _toDouble(json['lat']),
      lng: json['lng'] == null ? null : _toDouble(json['lng']),
    );
  }

  Listing copyWith({
    String? status,
    DateTime? reservedUntil,
    bool clearReservedUntil = false,
    double? lat,
    double? lng,
    List<String>? photoUrls,
  }) {
    return Listing(
      id: id,
      ownerId: ownerId,
      title: title,
      description: description,
      category: category,
      subcategory: subcategory,
      authorName: authorName,
      authorLevel: authorLevel,
      authorRating: authorRating,
      authorIsFounder: authorIsFounder,
      photosCount: photosCount,
      photoUrls: photoUrls ?? this.photoUrls,
      distanceKm: distanceKm,
      status: status ?? this.status,
      reservedUntil: clearReservedUntil ? null : (reservedUntil ?? this.reservedUntil),
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'reserved':
        return 'Забронировано';
      case 'given':
        return 'Отдано';
      case 'hidden':
        return 'Скрыто';
      default:
        return 'Активно';
    }
  }

  static List<String> _parsePhotoUrls(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.parse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }
}
