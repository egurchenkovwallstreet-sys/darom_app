import 'package:flutter/material.dart';

/// Дизайн-система «Даром» — тёплый премиум (крем, коралл, изумруд).
class AppColors {
  AppColors._();

  // --- Design tokens ---
  static const background = Color(0xFFF9F6F0);
  static const backgroundStart = background;
  static const backgroundEnd = Color(0xFFF3EDE4);
  static const backgroundWarm = Color(0xFFFFF8F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGlass = Color(0xF5FFFFFF);

  static const primary = Color(0xFFFF5A36);
  static const primaryDark = Color(0xFFE84E2D);
  static const secondary = Color(0xFF2D6A4F);

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF737373);
  static const borderSoft = Color(0x0F000000);
  static const borderDivider = Color(0x0F000000);
  static const ambientPeach = Color(0xFFFFF0E8);
  static const ambientMint = Color(0xFFE8F5F0);
  static const glassHighlight = Color(0x99FFFFFF);
  static const glassBorder = Color(0x59FFFFFF);

  static const danger = Color(0xFFDC2626);
  static const gold = Color(0xFFD4A574);
  static const white = Color(0xFFFFFFFF);

  // --- Aliases (совместимость со старым кодом) ---
  static const accent = primary;
  static const accentDark = primaryDark;
  static const accentSecondary = secondary;
  static const categoryIcon = secondary;
  static const darkBlue = textPrimary;
  static const teal = secondary;
  static const cyan = primary;
  static const red = danger;

  static const pillTrack = Color(0x0A000000);

  static const appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );

  static const appBackgroundGradientWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundWarm, backgroundEnd],
  );

  static LinearGradient subtleOverlay({double opacity = 1.0}) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          background.withOpacity(0.0),
          backgroundEnd.withOpacity(0.35 * opacity),
        ],
      );

  static const midnightGlowGradient = appBackgroundGradient;
  static const warmTrustGradient = appBackgroundGradientWarm;

  static LinearGradient warmTrustOverlay({double opacity = 1.0}) => subtleOverlay(opacity: opacity);
  static LinearGradient overlayGradient({double opacity = 1.0}) => subtleOverlay(opacity: opacity);
}