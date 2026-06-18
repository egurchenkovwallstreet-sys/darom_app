import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/listing.dart';
import '../models/map_marker.dart';
import '../services/favorites_api.dart';
import '../services/listings_api.dart';
import '../services/location_service.dart';
import '../widgets/listing_tile_card.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/osm_map_widget.dart';
import '../theme/app_colors.dart';
import 'subcategories_screen.dart';
import 'listing_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String phoneNumber;
  final String? userId;
  final bool inShell;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.phoneNumber,
    this.userId,
    this.inShell = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  static const _searchFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFF00BFFF), width: 1.5),
  );

  static const List<double> _radiusKmValues = [1, 2, 5, 10, 50];
  final List<String> _radiusLabels = ['1 км', '2 км', '5 км', '10 км', 'Весь город'];
  static const List<String> _radiusButtonLabels = ['1', '2', '5', '10', 'Город'];
  final List<String> _categories = [
    'Одежда', 'Мебель', 'Детское', 'Электроника',
    'Книги', 'Посуда', 'Спорт', 'Другое',
  ];
  final List<IconData> _categoryIcons = [
    Icons.checkroom, Icons.chair, Icons.toys, Icons.smartphone,
    Icons.menu_book, Icons.restaurant, Icons.fitness_center, Icons.category,
  ];

  @override
  void initState() {
    super.initState();
    _initLocationAndListings();
    _loadFavoriteIds();
  }

  @override
  void dispose() {
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

  Future<void> _initLocationAndListings() async {
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _position = position ?? GeoPosition.moscow;
      _locationHint = position == null
          ? (_locationService.needsHttpsForGeo
              ? 'С телефона геолокация по Wi‑Fi недоступна — показан центр Москвы'
              : 'Геолокация недоступна — показан центр Москвы')
          : null;
      _loadingLocation = false;
    });

    await _loadNearbyListings();
  }

  Future<void> _loadNearbyListings() async {
    setState(() {
      _loadingListings = true;
      _listingsError = null;
    });

    try {
      final items = await _listingsApi.fetchNearby(
        lat: _position.lat,
        lng: _position.lng,
        radiusKm: _currentRadiusKm,
      );
      if (!mounted) return;
      setState(() {
        _nearbyListings = items;
        _loadingListings = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _nearbyListings = [];
        _loadingListings = false;
        _listingsError = error is ListingsApiException
            ? error.message
            : 'Сервер не отвечает — запустите backend (Терминал 1: npm run dev)';
      });
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
          ),
        )
        .toList();

    return _spreadOverlappingMarkers(raw);
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
    ).then((_) => _loadFavoriteIds());
  }

  List<MapMarker> _spreadOverlappingMarkers(List<MapMarker> markers) {
    final groups = <String, List<MapMarker>>{};

    for (final marker in markers) {
      final key =
          '${marker.lat.toStringAsFixed(4)}:${marker.lng.toStringAsFixed(4)}';
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
          ),
        );
      }
    }

    return spread;
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF00BFFF),
                              width: 2,
                            ),
                          ),
                          child: Icon(Icons.person, color: Color(0xFF00BFFF)),
                        )
                            .animate(
                              onPlay: (controller) => controller.repeat(reverse: true),
                            )
                            .animate()
                            .scale(
                              duration: Duration(seconds: 2),
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .scale(
                              duration: Duration(seconds: 2),
                              curve: Curves.easeInOut,
                            ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Привет, ${widget.userName}!',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFFFFF),
                                ),
                              )
                                  .animate(
                                    delay: Duration(milliseconds: 200),
                                  )
                                  .fadeIn(duration: Duration(milliseconds: 800))
                                  .slideX(begin: -0.3, end: 0),
                              Text(
                                'Что ищешь?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFFFFFF).withOpacity(0.7),
                                ),
                              )
                                  .animate(
                                    delay: Duration(milliseconds: 400),
                                  )
                                  .fadeIn(duration: Duration(milliseconds: 800))
                                  .slideX(begin: -0.3, end: 0),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF00BFFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Новичок',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(
                              delay: Duration(milliseconds: 600),
                            )
                            .fadeIn(duration: Duration(milliseconds: 800))
                            .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
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
                    )
                        .animate(
                          delay: Duration(milliseconds: 300),
                        )
                        .fadeIn(duration: Duration(milliseconds: 800))
                        .slideY(begin: -0.3, end: 0),
                  ),
                  const SizedBox(height: 8),

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
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Row(
                      children: [
                        const Text(
                          '📦 Категории',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF00BFFF).withOpacity(0.9),
                          size: 22,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'листайте',
                          style: TextStyle(
                            color: const Color(0xFF00BFFF).withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_locationHint != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                              child: Text(
                                _locationHint!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFFFFFF).withOpacity(0.6),
                                ),
                              ),
                            ),
                          if (_listingsError != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                              child: Text(
                                _listingsError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _showListView
                                ? _buildNearbyList()
                                : SizedBox(
                                    height: 130,
                                    child: _loadingLocation
                                        ? _buildMapPlaceholder('Определяем местоположение...')
                                        : OsmMapWidget(
                                            centerLat: _position.lat,
                                            centerLng: _position.lng,
                                            zoom: _currentRadiusKm <= 2 ? 14 : 12,
                                            radiusKm: _currentRadiusKm,
                                            markers: _mapMarkers,
                                            isApproximateLocation: _locationHint != null,
                                            onMarkerTap: (marker) {
                                              setState(() => _selectedMarkerId = marker.id);
                                            },
                                          ),
                                  ),
                          ),
                          if (_selectedListing != null && !_showListView)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF001F3F).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.card_giftcard,
                                      color: Color(0xFF00BFFF),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectedListing!.title,
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
                                      onPressed: () => _openListing(_selectedListing!),
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
                          if (_loadingListings && !_showListView)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00BFFF),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTapDown: (_) => setState(() => _pressedCategoryIndex = index),
                                onTapUp: (_) {
                                  setState(() => _pressedCategoryIndex = -1);
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
                                },
                                onTapCancel: () => setState(() => _pressedCategoryIndex = -1),
                                child: AnimatedScale(
                                  scale: _pressedCategoryIndex == index ? 1.08 : 1.0,
                                  duration: Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF001F3F).withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.categoryIcon,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.categoryIcon.withOpacity(0.3),
                                          blurRadius: 5,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _categoryIcons[index],
                                          size: 24,
                                          color: AppColors.categoryIcon,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _categories[index],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.categoryIcon,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  ],
                ],
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

  Widget _buildNearbyList() {
    if (_loadingListings) {
      return SizedBox(
        height: 120,
        child: _buildMapPlaceholder('Загружаем объявления рядом...'),
      );
    }

    if (_nearbyListings.isEmpty) {
      return SizedBox(
        height: 120,
        child: _buildMapPlaceholder('В радиусе ${_radiusLabels[_radiusIndex]} объявлений нет'),
      );
    }

    return Column(
      children: _nearbyListings.take(8).map((listing) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
}