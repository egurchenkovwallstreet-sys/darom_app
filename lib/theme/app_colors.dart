import 'package:flutter/material.dart';

/// Дизайн-система «Даром» — доверие, экология, премиальная лёгкость.
class AppColors {
  AppColors._();

  // --- Новая палитра (источник правды) ---
  static const backgroundStart = Color(0xFFF8F9FA);
  static const backgroundEnd = Color(0xFFE8F5E9);
  static const backgroundWarm = Color(0xFFFFF8E1);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGlass = Color(0xCCFFFFFF);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const accent = Color(0xFF10B981);
  static const accentDark = Color(0xFF059669);
  static const accentSecondary = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const gold = Color(0xFFF59E0B);
  static const white = Color(0xFFFFFFFF);

  static const appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );

  static const appBackgroundGradientWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundWarm],
  );

  static LinearGradient subtleOverlay({double opacity = 1.0}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surface.withOpacity(0.4 * opacity),
          backgroundEnd.withOpacity(0.25 * opacity),
        ],
      );

  // --- Совместимость со старыми именами (не удалять — используются в коде) ---
  static const darkBlue = textPrimary;
  static const teal = accentDark;
  static const cyan = accent;
  static const red = danger;
  static const categoryIcon = accent;

  static const midnightGlowGradient = appBackgroundGradient;
  static const warmTrustGradient = appBackgroundGradientWarm;

  static LinearGradient warmTrustOverlay({double opacity = 1.0}) => subtleOverlay(opacity: opacity);

  static LinearGradient overlayGradient({double opacity = 1.0}) => subtleOverlay(opacity: opacity);
}