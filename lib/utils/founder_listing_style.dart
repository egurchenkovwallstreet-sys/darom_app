import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';

/// Визуальный приоритет объявлений основателей (первые 1000 пользователей).
class FounderListingStyle {
  FounderListingStyle._();

  static bool highlight(Listing listing) =>
      listing.authorIsFounder && !listing.isReserved;

  static Color borderColor(Listing listing, Color defaultColor) {
    if (listing.isReserved) return AppColors.textSecondary;
    if (highlight(listing)) return AppColors.gold;
    return defaultColor;
  }

  static Color backgroundColor(Listing listing) => AppColors.surface;

  static BoxDecoration cardDecoration(
    Listing listing,
    Color defaultBorderColor, {
    double borderWidth = 1,
    double radius = DaromDecorations.cardRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor(listing),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: DaromDecorations.cardShadow,
    );
  }
}