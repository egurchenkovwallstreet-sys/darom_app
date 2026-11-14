import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';

import '../models/listing.dart';
import '../utils/founder_listing_style.dart';
import '../widgets/favorite_button.dart';
import '../widgets/glass_surface.dart';
import '../widgets/listing_photo_image.dart';

class ListingTileCard extends StatefulWidget {
  const ListingTileCard({
    super.key,
    required this.listing,
    required this.phoneNumber,
    this.isFavorite = false,
    this.onFavoriteChanged,
    this.onTap,
    this.usePremiumGlass = false,
  });

  final Listing listing;
  final String phoneNumber;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;
  final VoidCallback? onTap;
  final bool usePremiumGlass;

  @override
  State<ListingTileCard> createState() => _ListingTileCardState();
}

class _ListingTileCardState extends State<ListingTileCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const defaultBorder = AppColors.accent;
    final border = FounderListingStyle.borderColor(widget.listing, defaultBorder);

    final content = Row(
      children: [
        ListingPhotoImage(
          url: widget.listing.photoUrls.isNotEmpty ? widget.listing.photoUrls.first : null,
          width: 56,
          height: 56,
          borderRadius: widget.usePremiumGlass ? 16 : 10,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.listing.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.listing.category} · ${widget.listing.distanceKm} км',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        FavoriteButton(
          listingId: widget.listing.id,
          phoneNumber: widget.phoneNumber,
          isFavorite: widget.isFavorite,
          onChanged: widget.onFavoriteChanged,
        ),
      ],
    );

    final Widget card;
    if (widget.usePremiumGlass) {
      card = GlassSurface(
        borderRadius: 24,
        borderColor: border,
        fillColor: FounderListingStyle.backgroundColor(widget.listing),
        fillOpacity: 0.55,
        softShadow: true,
        padding: const EdgeInsets.all(12),
        child: content,
      );
    } else {
      card = Container(
        padding: const EdgeInsets.all(12),
        decoration: FounderListingStyle.cardDecoration(
          widget.listing,
          defaultBorder,
        ),
        child: content,
      );
    }

    final interactive = GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: card,
      ),
    );

    return interactive;
  }
}