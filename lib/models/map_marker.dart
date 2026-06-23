class MapMarker {
  final String id;
  final double lat;
  final double lng;
  final String title;
  final bool isReserved;
  final bool isFounder;
  final DateTime? reservedUntil;

  const MapMarker({
    required this.id,
    required this.lat,
    required this.lng,
    required this.title,
    this.isReserved = false,
    this.isFounder = false,
    this.reservedUntil,
  });
}
