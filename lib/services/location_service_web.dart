import 'dart:async';
import 'dart:html' as html;

import 'geo_position.dart';

class LocationService {
  bool get _isLocalHost {
    final host = html.window.location.hostname;
    return host == 'localhost' || host == '127.0.0.1';
  }

  bool get _isSecureContext {
    if (_isLocalHost) return true;
    return html.window.isSecureContext ??
        html.window.location.protocol == 'https:';
  }

  /// Геолокация недоступна без HTTPS (кроме localhost при разработке).
  bool get needsHttpsForGeo => !_isSecureContext;

  Future<GeoLocationResult> locate() async {
    if (!_isSecureContext) {
      return const GeoLocationResult(status: GeoLocationStatus.notSecure);
    }

    final geolocation = html.window.navigator.geolocation;

    try {
      final position = await geolocation
          .getCurrentPosition(enableHighAccuracy: true)
          .timeout(const Duration(seconds: 15));
      final coords = position.coords;
      if (coords == null) {
        return const GeoLocationResult(status: GeoLocationStatus.unavailable);
      }

      return GeoLocationResult(
        status: GeoLocationStatus.ok,
        position: GeoPosition(
          lat: (coords.latitude ?? GeoPosition.moscow.lat).toDouble(),
          lng: (coords.longitude ?? GeoPosition.moscow.lng).toDouble(),
        ),
      );
    } on TimeoutException {
      return const GeoLocationResult(status: GeoLocationStatus.timeout);
    } on html.PositionError catch (error) {
      switch (error.code) {
        case html.PositionError.PERMISSION_DENIED:
          return const GeoLocationResult(status: GeoLocationStatus.denied);
        case html.PositionError.POSITION_UNAVAILABLE:
          return const GeoLocationResult(status: GeoLocationStatus.unavailable);
        case html.PositionError.TIMEOUT:
          return const GeoLocationResult(status: GeoLocationStatus.timeout);
        default:
          return const GeoLocationResult(status: GeoLocationStatus.unavailable);
      }
    } catch (_) {
      return const GeoLocationResult(status: GeoLocationStatus.unavailable);
    }
  }

  Future<GeoPosition?> getCurrentPosition() async {
    final result = await locate();
    return result.position;
  }
}
