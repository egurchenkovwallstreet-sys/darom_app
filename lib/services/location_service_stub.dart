import 'geo_position.dart';

class LocationService {
  bool get needsHttpsForGeo => false;

  Future<GeoLocationResult> locate() async {
    return const GeoLocationResult(
      status: GeoLocationStatus.ok,
      position: GeoPosition.moscow,
    );
  }

  Future<GeoPosition?> getCurrentPosition() async => GeoPosition.moscow;
}
