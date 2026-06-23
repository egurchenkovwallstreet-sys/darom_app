import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../theme/app_colors.dart';

/// Визуальный приоритет объявлений основателей (первые 1000 пользователей).
class FounderListingStyle {
  FounderListingStyle._();

  static bool highlight(Listing listing) =>
      listing.authorIsFounder && !listing.isReserved;

  static Color borderColor(Listing listing, Color defaultColor) {
    if (listing.isReserved) return const Color(0xFF9E9E9E);
    if (highlight(listing)) return AppColors.gold;
    return defaultColor;
  }

  static Color backgroundColor(Listing listing) {
    if (highlight(listing)) {
      return Color.alphaBlend(
        AppColors.gold.withOpacity(0.18),
        const Color(0xFF001F3F).withOpacity(0.85),
      );
    }
    return const Color(0xFF001F3F).withOpacity(0.85);
  }

  static BoxDecoration cardDecoration(
    Listing listing,
    Color defaultBorderColor, {
    double borderWidth = 1.5,
    double radius = 14,
  }) {
    return BoxDecoration(
      color: backgroundColor(listing),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor(listing, defaultBorderColor),
        width: borderWidth,
      ),
    );
  }
}
