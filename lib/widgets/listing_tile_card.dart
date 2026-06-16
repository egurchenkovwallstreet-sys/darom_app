import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../widgets/favorite_button.dart';
import '../widgets/listing_photo_image.dart';

class ListingTileCard extends StatelessWidget {
  const ListingTileCard({
    super.key,
    required this.listing,
    required this.phoneNumber,
    this.isFavorite = false,
    this.onFavoriteChanged,
    this.onTap,
  });

  final Listing listing;
  final String phoneNumber;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF001F3F).withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: listing.isReserved
                ? const Color(0xFF9E9E9E)
                : const Color(0xFF00BFFF),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            ListingPhotoImage(
              url: listing.photoUrls.isNotEmpty ? listing.photoUrls.first : null,
              width: 56,
              height: 56,
              borderRadius: 10,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.category} · ${listing.distanceKm} км',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFFFFFFF).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            FavoriteButton(
              listingId: listing.id,
              phoneNumber: phoneNumber,
              isFavorite: isFavorite,
              onChanged: onFavoriteChanged,
            ),
          ],
        ),
      ),
    );
  }
}
