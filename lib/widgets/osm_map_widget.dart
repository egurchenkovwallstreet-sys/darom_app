import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/map_marker.dart';
import '../theme/app_colors.dart';

class OsmMapWidget extends StatefulWidget {
  const OsmMapWidget({
    super.key,
    required this.centerLat,
    required this.centerLng,
    this.zoom = 12,
    this.radiusKm,
    required this.markers,
    this.isApproximateLocation = false,
    this.onMarkerTap,
  });

  final double centerLat;
  final double centerLng;
  final int zoom;
  final double? radiusKm;
  final List<MapMarker> markers;
  final bool isApproximateLocation;
  final void Function(MapMarker marker)? onMarkerTap;

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant OsmMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.centerLat != widget.centerLat ||
        oldWidget.centerLng != widget.centerLng ||
        oldWidget.zoom != widget.zoom) {
      _mapController.move(
        LatLng(widget.centerLat, widget.centerLng),
        widget.zoom.toDouble(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.centerLat, widget.centerLng);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00BFFF), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: widget.zoom.toDouble(),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.darom.app',
            ),
            if (widget.radiusKm != null && widget.radiusKm! > 0)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: widget.radiusKm! * 1000,
                    color: const Color(0x3300BFFF),
                    borderColor: const Color(0xFF00BFFF),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  ),
                ],
              ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: 120,
                  color: AppColors.gold.withOpacity(0.22),
                  borderColor: AppColors.gold,
                  borderStrokeWidth: 3,
                  useRadiusInMeter: true,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 76,
                  height: 96,
                  alignment: Alignment.bottomCenter,
                  child: _UserLocationPin(
                    isApproximate: widget.isApproximateLocation,
                  ),
                ),
                ...widget.markers.map(
                  (marker) => Marker(
                    point: LatLng(marker.lat, marker.lng),
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    child: _ListingPin(
                      title: marker.title,
                      isReserved: marker.isReserved,
                      onTap: widget.onMarkerTap == null
                          ? null
                          : () => widget.onMarkerTap!(marker),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserLocationPin extends StatelessWidget {
  const _UserLocationPin({required this.isApproximate});

  final bool isApproximate;

  @override
  Widget build(BuildContext context) {
    final label = isApproximate ? 'Примерно вы' : 'Вы здесь';

    return Tooltip(
      message: isApproximate
          ? 'Точное местоположение недоступно — показан центр Москвы'
          : 'Ваше местоположение',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
              border: Border.all(color: AppColors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.9),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle,
              color: AppColors.darkBlue,
              size: 26,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withOpacity(0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ListingPin extends StatelessWidget {
  const _ListingPin({
    required this.title,
    required this.isReserved,
    this.onTap,
  });

  final String title;
  final bool isReserved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isReserved ? const Color(0xFF757575) : AppColors.cyan;
    final borderColor = isReserved ? AppColors.gold : AppColors.white;

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: title,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.85),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isReserved ? Icons.lock_outline : Icons.card_giftcard,
              color: AppColors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
