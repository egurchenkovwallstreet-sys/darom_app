class GeoPosition {
  final double lat;
  final double lng;

  const GeoPosition({required this.lat, required this.lng});

  static const GeoPosition moscow = GeoPosition(lat: 55.7558, lng: 37.6173);
}
