import 'package:darom_app/theme/darom_decorations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/map_marker.dart';
import '../theme/app_colors.dart';
import '../utils/reservation_countdown.dart';

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
    this.interactive = true,
    this.showBorder = true,
    this.fillParent = false,
  });

  final double centerLat;
  final double centerLng;
  final int zoom;
  final double? radiusKm;
  final List<MapMarker> markers;
  final bool isApproximateLocation;
  final void Function(MapMarker marker)? onMarkerTap;
  final bool interactive;
  final bool showBorder;
  final bool fillParent;

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
    final borderRadius = widget.showBorder ? DaromDecorations.cardRadius : 0.0;

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: widget.zoom.toDouble(),
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
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
                color: AppColors.primary.withOpacity(0.08),
                borderColor: AppColors.primary.withOpacity(0.45),
                borderStrokeWidth: 1.5,
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
                width: 72,
                height: marker.isReserved ? 78 : 52,
                alignment: Alignment.center,
                child: _ListingPin(
                  title: marker.title,
                  isReserved: marker.isReserved,
                  isFounder: marker.isFounder,
                  reservedUntil: marker.reservedUntil,
                  onTap: widget.onMarkerTap == null
                      ? null
                      : () => widget.onMarkerTap!(marker),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    Widget content = map;
    if (widget.fillParent) {
      content = SizedBox.expand(child: map);
    }

    if (!widget.showBorder) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
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
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: DaromDecorations.cardShadow,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
              boxShadow: DaromDecorations.cardShadow,
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ListingPin extends StatefulWidget {
  const _ListingPin({
    required this.title,
    required this.isReserved,
    required this.isFounder,
    this.reservedUntil,
    this.onTap,
  });

  final String title;
  final bool isReserved;
  final bool isFounder;
  final DateTime? reservedUntil;
  final VoidCallback? onTap;

  @override
  State<_ListingPin> createState() => _ListingPinState();
}

class _ListingPinState extends State<_ListingPin> {
  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color iconColor;

    if (widget.isReserved) {
      bgColor = AppColors.textSecondary;
      iconColor = AppColors.white;
    } else if (widget.isFounder) {
      bgColor = AppColors.badgeFounderBg;
      iconColor = AppColors.badgeFounderText;
    } else {
      bgColor = AppColors.primary;
      iconColor = AppColors.white;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Tooltip(
        message: widget.title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  boxShadow: DaromDecorations.cardShadow,
                ),
                child: Icon(
                  widget.isReserved ? Icons.lock_outline : Icons.card_giftcard,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
            if (widget.isReserved && widget.reservedUntil != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
                  boxShadow: DaromDecorations.cardShadow,
                ),
                child: ReservationCountdownText(
                  until: widget.reservedUntil,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
