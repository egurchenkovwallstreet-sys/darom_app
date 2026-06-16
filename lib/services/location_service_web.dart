import 'dart:async';
import 'dart:html' as html;

import 'geo_position.dart';

class LocationService {
  bool get _isLocalHost {
    final host = html.window.location.hostname;
    return host == 'localhost' || host == '127.0.0.1';
  }

  Future<GeoPosition?> getCurrentPosition() async {
    if (!_isLocalHost) {
      return null;
    }

    final geolocation = html.window.navigator.geolocation;

    try {
      final position = await geolocation
          .getCurrentPosition(enableHighAccuracy: true)
          .timeout(const Duration(seconds: 10));
      final coords = position.coords;
      if (coords == null) return null;

      return GeoPosition(
        lat: (coords.latitude ?? GeoPosition.moscow.lat).toDouble(),
        lng: (coords.longitude ?? GeoPosition.moscow.lng).toDouble(),
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  bool get needsHttpsForGeo => !_isLocalHost;
}