import 'package:flutter/material.dart';

import '../data/map_radius_options.dart';
import '../models/listing.dart';
import '../models/map_marker.dart';
import '../services/listings_api.dart';
import '../services/location_service.dart';
import '../utils/map_marker_spread.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/osm_map_widget.dart';
import 'listing_screen.dart';

/// Полноэкранная карта объявлений рядом.
class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({
    super.key,
    required this.position,
    required this.initialRadiusIndex,
    required this.isApproximateLocation,
    required this.phoneNumber,
    this.userId,
    required this.favoriteIds,
  });

  final GeoPosition position;
  final int initialRadiusIndex;
  final bool isApproximateLocation;
  final String phoneNumber;
  final String? userId;
  final Set<String> favoriteIds;

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  final ListingsApi _listingsApi = ListingsApi();

  late int _radiusIndex;
  int _pressedRadiusIndex = -1;
  List<Listing> _listings = [];
  bool _loading = true;
  String? _error;
  String? _selectedMarkerId;
  late Set<String> _favoriteIds;

  @override
  void initState() {
    super.initState();
    _radiusIndex = widget.initialRadiusIndex;
    _favoriteIds = Set<String>.from(widget.favoriteIds);
    _loadListings();
  }

  @override
  void dispose() {
    _listingsApi.dispose();
    super.dispose();
  }

  double get _radiusKm => MapRadiusOptions.kmAt(_radiusIndex);

  List<MapMarker> get _markers {
    final raw = _listings
        .where((item) => item.lat != null && item.lng != null)
        .map(
          (item) => MapMarker(
            id: item.id,
            lat: item.lat!,
            lng: item.lng!,
            title: item.title,
            isReserved: item.isReserved,
          ),
        )
        .toList();
    return spreadOverlappingMapMarkers(raw);
  }

  Listing? get _selectedListing {
    if (_selectedMarkerId == null) return null;
    for (final item in _listings) {
      if (item.id == _selectedMarkerId) return item;
    }
    return null;
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedMarkerId = null;
    });

    try {
      final items = await _listingsApi.fetchNearby(
        lat: widget.position.lat,
        lng: widget.position.lng,
        radiusKm: _radiusKm,
      );
      if (!mounted) return;
      setState(() {
        _listings = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _listings = [];
        _loading = false;
        _error = error is ListingsApiException
            ? error.message
            : 'Не удалось загрузить объявления';
      });
    }
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

  void _close() {
    Navigator.pop(context, _radiusIndex);
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
                    onPressed: _close,
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
                      _loading ? '…' : '${_listings.length} шт.',
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
              child: Stack(
                children: [
                  OsmMapWidget(
                    centerLat: widget.position.lat,
                    centerLng: widget.position.lng,
                    zoom: MapRadiusOptions.zoomFor(_radiusKm),
                    radiusKm: _radiusKm,
                    markers: _markers,
                    isApproximateLocation: widget.isApproximateLocation,
                    showBorder: false,
                    fillParent: true,
                    onMarkerTap: (marker) {
                      setState(() => _selectedMarkerId = marker.id);
                    },
                  ),
                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 8,
                    child: _buildRadiusOverlay(),
                  ),
                  if (_error != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _buildErrorBanner(_error!),
                    ),
                ],
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

  Widget _buildRadiusOverlay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00BFFF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Радиус:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  MapRadiusOptions.labels[_radiusIndex],
                  style: const TextStyle(
                    color: Color(0xFF00BFFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              MapRadiusOptions.buttonLabels.length,
              (index) => Expanded(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressedRadiusIndex = index),
                  onTapUp: (_) {
                    if (_radiusIndex == index) {
                      setState(() => _pressedRadiusIndex = -1);
                      return;
                    }
                    setState(() {
                      _pressedRadiusIndex = -1;
                      _radiusIndex = index;
                    });
                    _loadListings();
                  },
                  onTapCancel: () => setState(() => _pressedRadiusIndex = -1),
                  child: AnimatedScale(
                    scale: _pressedRadiusIndex == index ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Container(
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _radiusIndex == index
                            ? const Color(0xFF00BFFF)
                            : const Color(0xFF008C8C).withOpacity(0.35),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            MapRadiusOptions.buttonLabels[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _radiusIndex == index
                                  ? Colors.white
                                  : const Color(0xFFFFFFFF).withOpacity(0.85),
                              fontWeight: FontWeight.bold,
                              fontSize: index == 4 ? 10 : 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF5722), width: 1.5),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFF5722), fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
