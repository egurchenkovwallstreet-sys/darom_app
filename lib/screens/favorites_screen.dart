import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../services/favorites_api.dart';
import '../widgets/listing_tile_card.dart';
import '../widgets/midnight_glow_screen.dart';
import 'listing_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final String phoneNumber;
  final String? currentUserId;
  final bool inShell;

  const FavoritesScreen({
    super.key,
    required this.phoneNumber,
    this.currentUserId,
    this.inShell = false,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesApi _api = FavoritesApi();
  late Future<List<Listing>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
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
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Listing>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
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
                              color: const Color(0xFFFFFFFF).withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _reload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BFFF),
                              foregroundColor: const Color(0xFF001F3F),
                            ),
                            child: const Text('Повторить'),
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
                            color: const Color(0xFF00BFFF).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Пока пусто\nНажмите ❤️ на объявлении, чтобы сохранить',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFFFFFFF).withOpacity(0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF00BFFF),
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
