import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/listing.dart';
import '../models/map_marker.dart';
import '../services/favorites_api.dart';
import '../services/listings_api.dart';
import '../services/location_service.dart';
import '../services/refresh_intervals.dart';
import '../l10n/app_localizations.dart';
import '../l10n/category_localizations.dart';
import '../services/locale_service.dart';
import '../data/app_categories.dart';
import '../data/map_radius_options.dart';
import '../utils/instant_on_web.dart';
import '../utils/map_marker_spread.dart';
import '../widgets/glass_surface.dart';
import '../widgets/listing_tile_card.dart';
import '../widgets/deferred_screen.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/osm_map_widget.dart';
import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';
import 'subcategories_screen.dart' deferred as subcategories;
import 'listing_screen.dart' deferred as listing_screen;
import 'nearby_map_screen.dart' deferred as nearby_map;

final _listingLibrary = DeferredLibrary(listing_screen.loadLibrary);
final _subcategoriesLibrary = DeferredLibrary(subcategories.loadLibrary);
final _nearbyMapLibrary = DeferredLibrary(nearby_map.loadLibrary);

/// Экраны, открываемые с главной, в порядке фоновой докачки
/// (карточка объявления — самая частая).
final homeDeferredLibraries = [
  _listingLibrary,
  _subcategoriesLibrary,
  _nearbyMapLibrary,
];

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
  static const double _blockGap = 12;
  static const double _mapPreviewHeight = 260;

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

  AppLocalizations get _l10n => AppLocalizations(LocaleService.instance.locale);

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
        _searchError = _l10n.searchMinChars;
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
            : _l10n.errSearchBackend;
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
        return _l10n.locationDenied;
      case GeoLocationStatus.notSecure:
        return _l10n.locationNotSecure;
      case GeoLocationStatus.timeout:
        return _l10n.locationTimeout;
      case GeoLocationStatus.unavailable:
        return _l10n.locationUnavailable;
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
            : _l10n.errServerConnection;
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
        builder: (context) => DeferredScreen(
          library: _listingLibrary,
          builder: (_) => listing_screen.ListingScreen(
            listing: listing,
            phoneNumber: widget.phoneNumber,
            currentUserId: widget.userId,
            isFavorite: _favoriteIds.contains(listing.id),
          ),
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
        builder: (context) => DeferredScreen(
          library: _nearbyMapLibrary,
          builder: (_) => nearby_map.NearbyMapScreen(
            position: _position,
            initialRadiusIndex: _radiusIndex,
            isApproximateLocation: _locationHint != null,
            phoneNumber: widget.phoneNumber,
            userId: widget.userId,
            favoriteIds: _favoriteIds,
          ),
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

  double get _scrollBottomPadding => widget.inShell ? 118 : 24;

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);

    final slivers = <Widget>[
      SliverToBoxAdapter(child: _buildHeader(l10n)),
      _buildPinnedSearchBar(l10n),
      if (_showSearchResults) ..._buildSearchModeSlivers(l10n) else ..._buildMainModeSlivers(l10n),
      SliverPadding(padding: EdgeInsets.only(bottom: _scrollBottomPadding)),
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: slivers,
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final name = widget.userName.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isNotEmpty ? l10n.homeGreeting(name) : 'Даром',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(l10n.homeTitle, style: DaromDecorations.titleStyle(fontSize: 26)),
        ],
      ),
    );
  }

  SliverAppBar _buildPinnedSearchBar(AppLocalizations l10n) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 72,
      titleSpacing: 16,
      centerTitle: false,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      title: _buildSearchField(l10n),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return GlassSurface(
      borderRadius: DaromDecorations.inputRadius,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: TextField(
        controller: _searchController,
        style: DaromDecorations.fieldText.copyWith(fontSize: 15),
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
          fillColor: Colors.transparent,
          hintText: l10n.searchHint,
          hintStyle: DaromDecorations.fieldHint(fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 40),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                  onPressed: _clearSearch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  List<Widget> _buildSearchModeSlivers(AppLocalizations l10n) {
    final slivers = <Widget>[];

    if (_searchError != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _searchError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          ),
        ),
      );
    }

    if (_lastSearchQuery != null && !_isSearching && _searchError == null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _searchResults.isEmpty
                    ? l10n.searchNothingFound(_lastSearchQuery!)
                    : l10n.searchFoundCount(_searchResults.length),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_isSearching) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.textSecondary),
          ),
        ),
      );
      return slivers;
    }

    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final listing = _searchResults[index];
              return _buildAnimatedListingTile(index, listing);
            },
            childCount: _searchResults.length,
          ),
        ),
      ),
    );

    return slivers;
  }

  List<Widget> _buildMainModeSlivers(AppLocalizations l10n) {
    final slivers = <Widget>[
      SliverToBoxAdapter(child: _buildMapListToggle(l10n)),
      const SliverToBoxAdapter(child: SizedBox(height: _blockGap)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: DaromDecorations.solidCard(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (!_showListView)
                  SizedBox(height: _mapPreviewHeight, child: _buildMapPreview()),
                _buildRadiusSection(l10n),
              ],
            ),
          ),
        ),
      ),
    ];

    if (_locationHint != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationHint!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadingLocation ? null : _retryLocation,
                  child: Text(
                    l10n.repeatButton,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_listingsError != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, _blockGap, 16, 0),
            child: Text(
              _listingsError!,
              style: const TextStyle(fontSize: 14, color: AppColors.danger),
            ),
          ),
        ),
      );
    }

    if (!_showListView && _selectedListing != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, _blockGap, 16, 0),
            child: _buildSelectedListingCard(),
          ),
        ),
      );
    }

    if (_showListView) {
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: _blockGap)));
      slivers.addAll(_buildNearbyListSlivers());
    }

    final wide = MediaQuery.sizeOf(context).width >= 720;
    slivers.addAll([
      const SliverToBoxAdapter(child: SizedBox(height: 28)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.categories, style: DaromDecorations.titleStyle(fontSize: 20)),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: _blockGap)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: wide ? 4 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 64,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildCategoryTile(index),
            childCount: _categories.length,
          ),
        ),
      ),
    ]);

    return slivers;
  }

  Widget _buildMapListToggle(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.tabTrack,
          borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
        ),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: _mapListSegment(
                  l10n.tabMap,
                  icon: Icons.map_outlined,
                  selected: !_showListView,
                  onTap: () => setState(() => _showListView = false),
                  pressed: _pressedMapButton,
                  onPressDown: () => setState(() => _pressedMapButton = true),
                  onPressUp: () => setState(() => _pressedMapButton = false),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _mapListSegment(
                  l10n.tabList,
                  icon: Icons.view_agenda_outlined,
                  selected: _showListView,
                  onTap: () => setState(() => _showListView = true),
                  pressed: _pressedListButton,
                  onPressDown: () => setState(() => _pressedListButton = true),
                  onPressUp: () => setState(() => _pressedListButton = false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapListSegment(
    String label, {
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool pressed,
    required VoidCallback onPressDown,
    required VoidCallback onPressUp,
  }) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTapDown: (_) => onPressDown(),
      onTapUp: (_) => onPressUp(),
      onTapCancel: onPressUp,
      onTap: onTap,
      child: AnimatedScale(
        scale: pressed ? 0.98 : 1.0,
        duration: DaromDecorations.interactionDuration,
        curve: DaromDecorations.interactionCurve,
        child: AnimatedContainer(
          duration: DaromDecorations.interactionDuration,
          curve: DaromDecorations.interactionCurve,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
            boxShadow: selected ? DaromDecorations.cardShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.radiusLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _radiusLabels[_radiusIndex],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildRadiusCountBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              _radiusButtonLabels.length,
              (index) {
                final selected = _radiusIndex == index;
                return Expanded(
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
                      scale: _pressedRadiusIndex == index ? 0.97 : 1.0,
                      duration: DaromDecorations.interactionDuration,
                      curve: DaromDecorations.interactionCurve,
                      child: AnimatedContainer(
                        duration: DaromDecorations.interactionDuration,
                        curve: DaromDecorations.interactionCurve,
                        height: 38,
                        margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: selected ? null : AppColors.tabTrack,
                          gradient: selected ? AppColors.brandGradient : null,
                          borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _radiusButtonLabels[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? AppColors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNearbyListSlivers() {
    if (_loadingListings) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: SizedBox(height: 200, child: _buildMapPlaceholder(_l10n.loadingListings)),
          ),
        ),
      ];
    }

    if (_nearbyListings.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: _buildMapPlaceholder(
                _isAllListingsMode
                    ? _l10n.noListingsOnMap
                    : _l10n.noListingsInRadius(_radiusLabels[_radiusIndex]),
              ),
            ),
          ),
        ),
      ];
    }

    final items = _nearbyListings.take(8).toList();
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildAnimatedListingTile(index, items[index]),
            childCount: items.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildAnimatedListingTile(int index, Listing listing) {
    final card = Padding(
      padding: const EdgeInsets.only(bottom: _blockGap),
      child: ListingTileCard(
        listing: listing,
        phoneNumber: widget.phoneNumber,
        isFavorite: _favoriteIds.contains(listing.id),
        usePremiumGlass: true,
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

    return animateUnlessWeb(
      card,
      (child) => child
          .animate(delay: Duration(milliseconds: 55 * index))
          .fadeIn(duration: const Duration(milliseconds: 480), curve: Curves.easeOutCubic)
          .slideY(begin: 0.12, end: 0, curve: Curves.fastOutSlowIn),
    );
  }

  Widget _buildMapPreview() {
    if (_loadingLocation) {
      return _buildMapPlaceholder(_l10n.loadingLocation);
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
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
                boxShadow: DaromDecorations.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_full_rounded, color: AppColors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _l10n.openButton,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: AppColors.secondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              listing.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _openListing(listing),
            child: Text(
              _l10n.openButton,
              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
            onPressed: () => setState(() => _selectedMarkerId = null),
          ),
        ],
      ),
    );
  }

  void _openCategory(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeferredScreen(
          library: _subcategoriesLibrary,
          builder: (_) => subcategories.SubcategoriesScreen(
            categoryName: _categories[index],
            categoryColor: AppColors.categoryIcon,
            phoneNumber: widget.phoneNumber,
            currentUserId: widget.userId,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(int index) {
    final pressed = _pressedCategoryIndex == index;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedCategoryIndex = index),
      onTapUp: (_) {
        setState(() => _pressedCategoryIndex = -1);
        _openCategory(index);
      },
      onTapCancel: () => setState(() => _pressedCategoryIndex = -1),
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: DaromDecorations.interactionDuration,
        curve: DaromDecorations.interactionCurve,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: DaromDecorations.solidCard(),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
                ),
                child: Icon(_categoryIcons[index], size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _l10n.categoryLabel(_categories[index]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusCountBadge() {
    if (_loadingListings) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textSecondary,
        ),
      );
    }

    final count = _nearbyListings.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
      ),
      child: Text(
        _l10n.homeItemsCount(count),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(String message) {
    return GlassSurface(
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}