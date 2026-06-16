import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/listing.dart';
import '../services/listings_api.dart';
import '../widgets/listing_photo_image.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'listing_screen.dart';

class ListingsFeedScreen extends StatefulWidget {
  final String categoryName;
  final String subcategoryName;
  final Color categoryColor;
  final String phoneNumber;
  final String? currentUserId;

  const ListingsFeedScreen({
    super.key,
    required this.categoryName,
    required this.subcategoryName,
    required this.categoryColor,
    required this.phoneNumber,
    this.currentUserId,
  });

  @override
  State<ListingsFeedScreen> createState() => _ListingsFeedScreenState();
}

class _ListingsFeedScreenState extends State<ListingsFeedScreen> {
  final ListingsApi _api = ListingsApi();
  late Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _loadListings();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<List<Listing>> _loadListings() {
    return _api.fetchBySubcategory(
      category: widget.categoryName,
      subcategory: widget.subcategoryName,
    );
  }

  void _retry() {
    setState(() {
      _listingsFuture = _loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF001F3F).withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subcategoryName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        Text(
                          widget.categoryName,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFFFFFFF).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<Listing>>(
                    future: _listingsFuture,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length;
                      final label = count == null ? '…' : '$count';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.categoryColor.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: widget.categoryColor, width: 2),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: widget.categoryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Listing>>(
                future: _listingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: widget.categoryColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      categoryColor: widget.categoryColor,
                      message: snapshot.error.toString(),
                      onRetry: _retry,
                    );
                  }

                  final listings = snapshot.data ?? [];

                  if (listings.isEmpty) {
                    return _EmptyState(categoryColor: widget.categoryColor);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      return _ListingCard(
                        listing: listings[index],
                        categoryColor: widget.categoryColor,
                        index: index,
                        phoneNumber: widget.phoneNumber,
                        currentUserId: widget.currentUserId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Color categoryColor;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.categoryColor,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: categoryColor),
            const SizedBox(height: 16),
            const Text(
              'Не удалось загрузить объявления',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFFFFFFFF).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Проверьте, что backend запущен:\nnpm run dev в папке backend',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFFFFFFF).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryActionButton(
              label: 'Повторить',
              height: 48,
              fontSize: 16,
              borderRadius: 24,
              gradientColors: PrimaryActionButton.primaryShortGradient,
              shadowColor: categoryColor,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color categoryColor;

  const _EmptyState({required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Пока нет объявлений в этой категории',
        style: TextStyle(
          fontSize: 16,
          color: const Color(0xFFFFFFFF).withOpacity(0.7),
        ),
      ),
    );
  }
}

class _ListingCard extends StatefulWidget {
  final Listing listing;
  final Color categoryColor;
  final int index;
  final String phoneNumber;
  final String? currentUserId;

  const _ListingCard({
    required this.listing,
    required this.categoryColor,
    required this.index,
    required this.phoneNumber,
    this.currentUserId,
  });

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final isReserved = listing.isReserved;
    final cardColor = isReserved ? const Color(0xFF9E9E9E) : widget.categoryColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingScreen(
              listing: listing,
              phoneNumber: widget.phoneNumber,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Opacity(
          opacity: isReserved ? 0.65 : 1.0,
          child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF001F3F).withOpacity(0.85),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cardColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              ListingPhotoImage(
                url: listing.photoUrls.isNotEmpty ? listing.photoUrls.first : null,
                width: 70,
                height: 70,
                borderRadius: 12,
                iconColor: cardColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isReserved)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Забронировано',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ),
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFFFFFFF).withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.place, size: 14, color: cardColor),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.distanceKm} км',
                          style: TextStyle(
                            fontSize: 12,
                            color: cardColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.authorRating}',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFFFFFFFF).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cardColor),
            ],
          ),
        ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * widget.index))
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
