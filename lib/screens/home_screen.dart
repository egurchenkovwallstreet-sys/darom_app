import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/listing.dart';
import '../models/map_marker.dart';
import '../services/favorites_api.dart';
import '../services/listings_api.dart';
import '../services/location_service.dart';
import '../services/refresh_intervals.dart';
import '../data/app_categories.dart';
import '../data/map_radius_options.dart';
import '../utils/instant_on_web.dart';
import '../utils/map_marker_spread.dart';
import '../widgets/listing_tile_card.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/osm_map_widget.dart';
import '../theme/app_colors.dart';
import 'subcategories_screen.dart';
import 'listing_screen.dart';
import 'nearby_map_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String phoneNumber;
  final String? userId;
  final bool inShell;
  final bool isActiveTab;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.phoneNumber,
    this.userId,
    this.inShell = false,
    this.isActiveTab = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _blockGap = 3.8;
  static const double _categoryChipHeight = 43.2; // 36 + 20%
  static const double _categoryIconSize = 21.6; // 18 + 20%
  static const double _categoryFontSize = 14.0;

  int _radiusIndex = 2;
  int _pressedRadiusIndex = -1;
  int _pressedCategoryIndex = -1;
  bool _pressedMapButton = false;
  bool _pressedListButton = false;
  bool _showListView = false;

  final LocationService _locationService = LocationService();
  final ListingsApi _listingsApi = ListingsApi();
  GeoPosition _position = GeoPosition.moscow;
  List<Listing> _nearbyListings = [];
  bool _loadingLocation = true;
  bool _loadingListings = false;
  String? _locationHint;
  String? _listingsError;
  String? _selectedMarkerId;

  final TextEditingController _searchController = TextEditingController();
  final FavoritesApi _favoritesApi = FavoritesApi();
  Set<String> _favoriteIds = {};
  List<Listing> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  String? _searchError;
  String? _lastSearchQuery;
  Timer? _listingsPollTimer;
  bool _listingsLoadInFlight = false;

  static const _searchFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFF00BFFF), width: 1.5),
  );

  static const List<double> _radiusKmValues = MapRadiusOptions.kmValues;
  final List<String> _radiusLabels = MapRadiusOptions.labels;
  static const List<String> _radiusButtonLabels = MapRadiusOptions.buttonLabels;
  final List<String> _categories = AppCategories.categoryNames;
  final List<IconData> _categoryIcons = AppCategories.all.map((c) => c.icon).toList();

  @override
  void initState() {
    super.initState();
    _initLocationAndListings();
    _loadFavoriteIds();
    if (widget.isActiveTab) {
      _startListingsPoll();
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab == oldWidget.isActiveTab) return;
    if (widget.isActiveTab) {
      _startListingsPoll();
      _loadNearbyListings(silent: true);
    } else {
      _stopListingsPoll();
    }
  }

  void _startListingsPoll() {
    _listingsPollTimer?.cancel();
    _listingsPollTimer = Timer.periodic(RefreshIntervals.homeListings, (_) {
      if (_showSearchResults || _loadingLocation) return;
      _loadNearbyListings(silent: true);
    });
  }

  void _stopListingsPoll() {
    _listingsPollTimer?.cancel();
    _listingsPollTimer = null;
  }

  @override
  void dispose() {
    _stopListingsPoll();
    _searchController.dispose();
    _favoritesApi.dispose();
    _listingsApi.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final ids = await _favoritesApi.fetchFavoriteIds(phone: widget.phoneNumber);
      if (!mounted) return;
      setState(() => _favoriteIds = ids);
    } catch (_) {}
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _searchError = 'Введите минимум 2 символа';
        _showSearchResults = true;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _showSearchResults = true;
      _lastSearchQuery = query;
    });

    try {
      final items = await _listingsApi.search(
        query: query,
        lat: _position.lat,
        lng: _position.lng,
        radiusKm: _currentRadiusKm,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = items;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchError = error is ListingsApiException
            ? error.message
            : 'Ошибка поиска — проверьте backend';
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _searchResults = [];
      _searchError = null;
      _lastSearchQuery = null;
    });
  }

  double get _currentRadiusKm => _radiusKmValues[_radiusIndex];

  bool get _isAllListingsMode => MapRadiusOptions.isAllListings(_radiusIndex);

  void _initLocationAndListings() {
    unawaited(_locationService.locate().then(_applyLocation));
  }

  Future<void> _retryLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationHint = null;
    });
    await _applyLocation(await _locationService.locate());
  }

  Future<void> _applyLocation(GeoLocationResult result) async {
    if (!mounted) return;

    setState(() {
      _position = result.positionOrMoscow;
      _locationHint = _locationHintFor(result.status);
      _loadingLocation = false;
    });

    await _loadNearbyListings();
  }

  String? _locationHintFor(GeoLocationStatus status) {
    switch (status) {
      case GeoLocationStatus.ok:
        return null;
      case GeoLocationStatus.denied:
        return 'Разрешите доступ к геолокации в браузере — пока показан центр Москвы';
      case GeoLocationStatus.notSecure:
        return 'Геолокация работает только по HTTPS — показан центр Москвы';
      case GeoLocationStatus.timeout:
        return 'Не удалось определить местоположение — показан центр Москвы';
      case GeoLocationStatus.unavailable:
        return 'Геолокация недоступна — показан центр Москвы';
    }
  }

  Future<void> _loadNearbyListings({bool silent = false}) async {
    if (_listingsLoadInFlight) return;
    _listingsLoadInFlight = true;

    if (!silent) {
      setState(() {
        _loadingListings = true;
        _listingsError = null;
      });
    }

    try {
      final items = _isAllListingsMode
          ? await _listingsApi.fetchAllForMap()
          : await _listingsApi.fetchNearby(
              lat: _position.lat,
              lng: _position.lng,
              radiusKm: _currentRadiusKm,
            );
      if (!mounted) return;
      setState(() {
        _nearbyListings = items;
        _loadingListings = false;
        _listingsError = null;
        if (_selectedMarkerId != null &&
            !items.any((item) => item.id == _selectedMarkerId)) {
          _selectedMarkerId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      if (silent) return;
      setState(() {
        _nearbyListings = [];
        _loadingListings = false;
        _listingsError = error is ListingsApiException
            ? error.message
            : 'Не удалось связаться с сервером. Проверьте интернет или откройте https://darom-app.online/';
      });
    } finally {
      _listingsLoadInFlight = false;
    }
  }

  List<MapMarker> get _mapMarkers {
    final raw = _nearbyListings
        .where((item) => item.lat != null && item.lng != null)
        .map(
          (item) => MapMarker(
            id: item.id,
            lat: item.lat!,
            lng: item.lng!,
            title: item.title,
            isReserved: item.isReserved,
            isFounder: item.authorIsFounder,
            reservedUntil: item.reservedUntil,
          ),
        )
        .toList();

    return spreadOverlappingMapMarkers(raw);
  }

  Listing? get _selectedListing {
    if (_selectedMarkerId == null) return null;
    for (final item in _nearbyListings) {
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
    ).then((deleted) {
      _loadFavoriteIds();
      if (deleted == true) {
        _loadNearbyListings();
      }
    });
  }

  void _openFullMap() {
    if (_loadingLocation) return;

    Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyMapScreen(
          position: _position,
          initialRadiusIndex: _radiusIndex,
          isApproximateLocation: _locationHint != null,
          phoneNumber: widget.phoneNumber,
          userId: widget.userId,
          favoriteIds: _favoriteIds,
        ),
      ),
    ).then((radiusIndex) {
      if (!mounted || radiusIndex == null || radiusIndex == _radiusIndex) return;
      setState(() => _radiusIndex = radiusIndex);
      _loadNearbyListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(child: _buildContent());
    if (widget.inShell) return content;
    return MidnightGlowScreen(child: content);
  }

  Widget _buildContent() {
    return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _runSearch(),
                      onChanged: (_) {
                        if (_searchController.text.isEmpty && _showSearchResults) {
                          _clearSearch();
                        } else {
                          setState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF001F3F).withOpacity(0.9),
                        hintText: 'Поиск: название или описание...',
                        hintStyle: TextStyle(
                          color: const Color(0xFFFFFFFF).withOpacity(0.45),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF00BFFF), size: 20),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFF80DEEA), size: 18),
                                onPressed: _clearSearch,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        enabledBorder: _searchFieldBorder,
                        focusedBorder: _searchFieldBorder.copyWith(
                          borderSide: const BorderSide(color: Color(0xFF80DEEA), width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  if (_showSearchResults) ...[
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _searchError!,
                            style: const TextStyle(color: Color(0xFFFF5722), fontSize: 13),
                          ),
                        ),
                      ),
                    if (_lastSearchQuery != null && !_isSearching && _searchError == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _searchResults.isEmpty
                                ? 'По запросу «$_lastSearchQuery» ничего не найдено'
                                : 'Найдено: ${_searchResults.length}',
                            style: TextStyle(
                              color: const Color(0xFF00BFFF).withOpacity(0.95),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    Expanded(child: _buildSearchResults()),
                  ] else ...[

                  animateUnlessWeb(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(0xFF001F3F).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Color(0xFF00BFFF), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTapDown: (_) => setState(() => _pressedMapButton = true),
                                onTapUp: (_) => setState(() => _pressedMapButton = false),
                                onTapCancel: () => setState(() => _pressedMapButton = false),
                                onTap: () => setState(() => _showListView = false),
                                child: AnimatedScale(
                                  scale: _pressedMapButton ? 1.08 : 1.0,
                                  duration: Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !_showListView
                                          ? Color(0xFF00BFFF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '🗺️ Карта',
                                        style: TextStyle(
                                          color: !_showListView
                                              ? Colors.white
                                              : Color(0xFFFFFFFF).withOpacity(0.7),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTapDown: (_) => setState(() => _pressedListButton = true),
                                onTapUp: (_) => setState(() => _pressedListButton = false),
                                onTapCancel: () => setState(() => _pressedListButton = false),
                                onTap: () => setState(() => _showListView = true),
                                child: AnimatedScale(
                                  scale: _pressedListButton ? 1.08 : 1.0,
                                  duration: Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _showListView
                                          ? Color(0xFF00BFFF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '📋 Список',
                                        style: TextStyle(
                                          color: _showListView
                                              ? Colors.white
                                              : Color(0xFFFFFFFF).withOpacity(0.7),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    (child) => child
                        .animate(
                          delay: Duration(milliseconds: 300),
                        )
                        .fadeIn(duration: Duration(milliseconds: 800))
                        .slideY(begin: -0.3, end: 0),
                  ),
                  SizedBox(height: _blockGap),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF001F3F).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF00BFFF), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  _radiusLabels[_radiusIndex],
                                  style: const TextStyle(
                                    color: Color(0xFF00BFFF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildRadiusCountBadge(),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              _radiusButtonLabels.length,
                              (index) => Expanded(
                                child: GestureDetector(
                                  onTapDown: (_) => setState(() => _pressedRadiusIndex = index),
                                  onTapUp: (_) {
                                    setState(() {
                                      _pressedRadiusIndex = -1;
                                      _radiusIndex = index;
                                    });
                                    _loadNearbyListings();
                                  },
                                  onTapCancel: () => setState(() => _pressedRadiusIndex = -1),
                                  child: AnimatedScale(
                                    scale: _pressedRadiusIndex == index ? 1.08 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeOut,
                                    child: Container(
                                      height: 32,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: _radiusIndex == index
                                            ? const Color(0xFF00BFFF)
                                            : const Color(0xFF008C8C).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _radiusButtonLabels[index],
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
                    )
                        .animate(
                          delay: Duration(milliseconds: 500),
                        )
                        .fadeIn(duration: Duration(milliseconds: 800))
                        .slideY(begin: -0.3, end: 0),
                  ),
                  SizedBox(height: _blockGap),

                  if (_locationHint != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _locationHint!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFFFFFF).withOpacity(0.6),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadingLocation ? null : _retryLocation,
                            child: const Text(
                              'Повторить',
                              style: TextStyle(
                                color: Color(0xFF00BFFF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_listingsError != null) ...[
                    SizedBox(height: _blockGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _listingsError!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFFF5722)),
                      ),
                    ),
                  ],
                  SizedBox(height: _blockGap),

                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _showListView ? _buildNearbyListScroll() : _buildMapPreview(),
                          ),
                        ),
                        if (_selectedListing != null && !_showListView) ...[
                          SizedBox(height: _blockGap),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildSelectedListingCard(),
                          ),
                        ],
                        if (_loadingListings && !_showListView) ...[
                          SizedBox(height: _blockGap),
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00BFFF),
                            ),
                          ),
                        ],
                        SizedBox(height: _blockGap),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Категории',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: _blockGap),
                        SizedBox(
                          height: _categoryChipHeight,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: _blockGap),
                            itemBuilder: (context, index) => _buildCategoryChip(index),
                          ),
                        ),
                        SizedBox(height: _blockGap),
                      ],
                    ),
                  ),
                  ],
                ],
    );
  }

  Widget _buildMapPreview() {
    if (_loadingLocation) {
      return _buildMapPlaceholder('Определяем местоположение...');
    }

    return GestureDetector(
      onTap: _openFullMap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AbsorbPointer(
            child: OsmMapWidget(
              centerLat: _position.lat,
              centerLng: _position.lng,
              zoom: MapRadiusOptions.zoomForIndex(_radiusIndex),
              radiusKm: _isAllListingsMode ? null : _currentRadiusKm,
              markers: _mapMarkers,
              isApproximateLocation: _locationHint != null,
              interactive: false,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF001F3F).withOpacity(0.88),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00BFFF), width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen_rounded, color: Color(0xFF00BFFF), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Открыть',
                    style: TextStyle(
                      color: Color(0xFF00BFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedListingCard() {
    final listing = _selectedListing!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00BFFF), width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Color(0xFF00BFFF), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              listing.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _openListing(listing),
            child: const Text(
              'Открыть',
              style: TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF80DEEA), size: 20),
            onPressed: () => setState(() => _selectedMarkerId = null),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyListScroll() {
    if (_loadingListings) {
      return _buildMapPlaceholder('Загружаем объявления рядом...');
    }

    if (_nearbyListings.isEmpty) {
      return _buildMapPlaceholder(
        _isAllListingsMode
            ? 'Объявлений на карте пока нет'
            : 'В радиусе ${_radiusLabels[_radiusIndex]} объявлений нет',
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: _nearbyListings.take(8).map((listing) {
        return Padding(
          padding: const EdgeInsets.only(bottom: _blockGap),
          child: ListingTileCard(
            listing: listing,
            phoneNumber: widget.phoneNumber,
            isFavorite: _favoriteIds.contains(listing.id),
            onFavoriteChanged: (isFavorite) {
              setState(() {
                if (isFavorite) {
                  _favoriteIds.add(listing.id);
                } else {
                  _favoriteIds.remove(listing.id);
                }
              });
            },
            onTap: () => _openListing(listing),
          ),
        );
      }).toList(),
    );
  }

  void _openCategory(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubcategoriesScreen(
          categoryName: _categories[index],
          categoryColor: AppColors.categoryIcon,
          phoneNumber: widget.phoneNumber,
          currentUserId: widget.userId,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int index) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedCategoryIndex = index),
      onTapUp: (_) {
        setState(() => _pressedCategoryIndex = -1);
        _openCategory(index);
      },
      onTapCancel: () => setState(() => _pressedCategoryIndex = -1),
      child: AnimatedScale(
        scale: _pressedCategoryIndex == index ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          height: _categoryChipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF001F3F).withOpacity(0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.categoryIcon, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _categoryIcons[index],
                size: _categoryIconSize,
                color: AppColors.categoryIcon,
              ),
              const SizedBox(width: 7),
              Text(
                _categories[index],
                style: const TextStyle(
                  fontSize: _categoryFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.categoryIcon,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final listing = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ListingTileCard(
            listing: listing,
            phoneNumber: widget.phoneNumber,
            isFavorite: _favoriteIds.contains(listing.id),
            onFavoriteChanged: (isFavorite) {
              setState(() {
                if (isFavorite) {
                  _favoriteIds.add(listing.id);
                } else {
                  _favoriteIds.remove(listing.id);
                }
              });
            },
            onTap: () => _openListing(listing),
          ),
        );
      },
    );
  }

  Widget _buildRadiusCountBadge() {
    if (_loadingListings) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF00BFFF),
        ),
      );
    }

    final count = _nearbyListings.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFFF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00BFFF), width: 1.5),
      ),
      child: Text(
        '$count шт.',
        style: const TextStyle(
          color: Color(0xFF00BFFF),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF001F3F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFF00BFFF), width: 2),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Color(0xFFFFFFFF).withOpacity(0.8)),
        ),
      ),
    );
  }
}