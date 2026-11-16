import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';

import '../models/listing.dart';
import '../services/favorites_api.dart';
import '../widgets/listing_tile_card.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'listing_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final String phoneNumber;
  final String? currentUserId;
  final bool inShell;
  final bool isActiveTab;

  const FavoritesScreen({
    super.key,
    required this.phoneNumber,
    this.currentUserId,
    this.inShell = false,
    this.isActiveTab = true,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesApi _api = FavoritesApi();
  Future<List<Listing>>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.isActiveTab) {
      _future = _load();
    }
  }

  @override
  void didUpdateWidget(FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab && !oldWidget.isActiveTab && _future == null) {
      setState(() => _future = _load());
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<List<Listing>> _load() {
    return _api.fetchFavorites(phone: widget.phoneNumber);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Избранное',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Listing>>(
              future: _future,
              builder: (context, snapshot) {
                if (_future == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryActionButton(
                            label: 'Повторить',
                            height: 48,
                            fontSize: 16,
                            borderRadius: 24,
                            gradientColors: PrimaryActionButton.primaryShortGradient,
                            onPressed: _reload,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: AppColors.accent.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Пока пусто\nНажмите на сердечко в объявлении, чтобы сохранить',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final listing = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ListingTileCard(
                          listing: listing,
                          phoneNumber: widget.phoneNumber,
                          isFavorite: true,
                          onFavoriteChanged: (isFavorite) {
                            if (!isFavorite) _reload();
                          },
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListingScreen(
                                  listing: listing,
                                  phoneNumber: widget.phoneNumber,
                                  currentUserId: widget.currentUserId,
                                  isFavorite: true,
                                ),
                              ),
                            );
                            _reload();
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.inShell) return content;
    return MidnightGlowScreen(child: content);
  }
}
