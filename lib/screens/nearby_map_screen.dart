import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../models/map_marker.dart';
import '../services/location_service.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/osm_map_widget.dart';
import 'listing_screen.dart';

/// Полноэкранная карта объявлений рядом.
class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({
    super.key,
    required this.position,
    required this.radiusKm,
    required this.zoom,
    required this.markers,
    required this.listings,
    required this.isApproximateLocation,
    required this.phoneNumber,
    this.userId,
    required this.favoriteIds,
  });

  final GeoPosition position;
  final double radiusKm;
  final int zoom;
  final List<MapMarker> markers;
  final List<Listing> listings;
  final bool isApproximateLocation;
  final String phoneNumber;
  final String? userId;
  final Set<String> favoriteIds;

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  String? _selectedMarkerId;
  late Set<String> _favoriteIds;

  @override
  void initState() {
    super.initState();
    _favoriteIds = Set<String>.from(widget.favoriteIds);
  }

  Listing? get _selectedListing {
    if (_selectedMarkerId == null) return null;
    for (final item in widget.listings) {
      if (item.id == _selectedMarkerId) return item;
    }
    return null;
  }

  void _openListing(Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingScreen(
          listing: listing,
          phoneNumber: widget.phoneNumber,
          currentUserId: widget.userId,
          isFavorite: _favoriteIds.contains(listing.id),
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedListing;

    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00BFFF)),
                    tooltip: 'Назад',
                  ),
                  const Expanded(
                    child: Text(
                      'Карта объявлений',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFFF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00BFFF), width: 1.5),
                    ),
                    child: Text(
                      '${widget.listings.length} шт.',
                      style: const TextStyle(
                        color: Color(0xFF00BFFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: OsmMapWidget(
                centerLat: widget.position.lat,
                centerLng: widget.position.lng,
                zoom: widget.zoom,
                radiusKm: widget.radiusKm,
                markers: widget.markers,
                isApproximateLocation: widget.isApproximateLocation,
                showBorder: false,
                fillParent: true,
                onMarkerTap: (marker) {
                  setState(() => _selectedMarkerId = marker.id);
                },
              ),
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001F3F).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Color(0xFF00BFFF), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selected.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openListing(selected),
                        child: const Text(
                          'Открыть',
                          style: TextStyle(
                            color: Color(0xFF00BFFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF80DEEA), size: 20),
                        onPressed: () => setState(() => _selectedMarkerId = null),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
