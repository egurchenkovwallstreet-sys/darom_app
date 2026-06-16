import 'geo_position.dart';

class LocationService {
  bool get needsHttpsForGeo => false;

  Future<GeoPosition?> getCurrentPosition() async => GeoPosition.moscow;
}
