import 'dart:math' as math;

import '../models/map_marker.dart';

/// Разводит маркеры с одинаковыми координатами, чтобы не перекрывались на карте.
List<MapMarker> spreadOverlappingMapMarkers(List<MapMarker> markers) {
  final groups = <String, List<MapMarker>>{};

  for (final marker in markers) {
    final key = '${marker.lat.toStringAsFixed(4)}:${marker.lng.toStringAsFixed(4)}';
    groups.putIfAbsent(key, () => []).add(marker);
  }

  final spread = <MapMarker>[];

  for (final group in groups.values) {
    if (group.length == 1) {
      spread.add(group.first);
      continue;
    }

    const baseRadius = 0.00012;
    final radius = baseRadius * math.sqrt(group.length);
    for (var i = 0; i < group.length; i++) {
      final angle = (2 * math.pi * i) / group.length;
      final item = group[i];
      spread.add(
        MapMarker(
          id: item.id,
          lat: item.lat + radius * math.sin(angle),
          lng: item.lng + radius * math.cos(angle),
          title: item.title,
          isReserved: item.isReserved,
          isFounder: item.isFounder,
          reservedUntil: item.reservedUntil,
        ),
      );
    }
  }

  return spread;
}
