import 'package:flutter/material.dart';

/// Дизайн-система «Даром» — тёплое доверие, нежный голубой (ui-ux-pro-max: Accessible & Ethical).
class AppColors {
  AppColors._();

  // --- Палитра «Нежное небо» ---
  static const backgroundStart = Color(0xFFF6FAFD);
  static const backgroundEnd = Color(0xFFE3EFF8);
  static const backgroundWarm = Color(0xFFFFF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGlass = Color(0xCCFFFFFF);
  static const textPrimary = Color(0xFF2D3F52);
  static const textSecondary = Color(0xFF5C6B7A);
  /// Основной акцент — мягкий голубой (не неон).
  static const accent = Color(0xFF6B9FD4);
  static const accentDark = Color(0xFF5A8BC0);
  /// Тёплый вторичный акцент (кнопки «второго плана», уют).
  static const accentSecondary = Color(0xFFE8B88A);
  static const danger = Color(0xFFDC2626);
  static const gold = Color(0xFFD4A574);
  static const white = Color(0xFFFFFFFF);
  static const borderSoft = Color(0xFFC5DFF0);

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
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surface.withOpacity(0.45 * opacity),
          backgroundEnd.withOpacity(0.35 * opacity),
        ],
      );

  // --- Совместимость со старыми именами ---
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