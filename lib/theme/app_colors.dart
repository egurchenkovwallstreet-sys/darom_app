import 'package:flutter/material.dart';

/// Дизайн-система «Даром» — Quiet Luxury: кремовый фон, белые поверхности, изумрудный акцент.
class AppColors {
  AppColors._();

  // --- Design tokens ---
  static const background = Color(0xFFF8F5F0);
  static const backgroundStart = background;
  static const backgroundEnd = background;
  static const backgroundWarm = background;
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGlass = surface;

  static const primary = Color(0xFF1E4D3B);
  static const primaryDark = Color(0xFF163A2C);
  static const secondary = primary;

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF737373);
  static const borderSoft = Color(0x00000000);
  static const borderDivider = Color(0xFFF0F0F0);
  static const glassHighlight = surface;
  static const glassBorder = Color(0x00000000);

  static const tabTrack = Color(0xFFEFEBE4);
  static const navActiveTint = Color(0xFFEEF4F1);
  static const chipSelected = primary;

  static const badgeFounderBg = Color(0xFFF3EAD3);
  static const badgeFounderText = Color(0xFF5C4A23);
  static const badgeNewbieBg = Color(0xFFE3F0E9);
  static const badgeNewbieText = primary;

  /// Ошибки и удаление: тёплый коричневый вместо красного (красный в продукте запрещён).
  static const danger = Color(0xFF7C5E48);
  static const gold = Color(0xFFB89B5E);
  static const white = Color(0xFFFFFFFF);

  // --- Aliases (совместимость со старым кодом) ---
  static const accent = primary;
  static const accentDark = primaryDark;
  static const accentSecondary = primary;
  static const categoryIcon = primary;
  static const darkBlue = textPrimary;
  static const teal = primary;
  static const cyan = primary;
  static const red = danger;
  static const ambientPeach = background;
  static const ambientMint = background;

  static const pillTrack = tabTrack;

  static const appBackgroundGradient = LinearGradient(
    colors: [background, background],
  );

  static const appBackgroundGradientWarm = appBackgroundGradient;

  static LinearGradient subtleOverlay({double opacity = 1.0}) => const LinearGradient(
        colors: [Color(0x00000000), Color(0x00000000)],
      );

  static const midnightGlowGradient = appBackgroundGradient;
  static const warmTrustGradient = appBackgroundGradient;

  static LinearGradient warmTrustOverlay({double opacity = 1.0}) => subtleOverlay(opacity: opacity);
  static LinearGradient overlayGradient({double opacity = 1.0}) => subtleOverlay(opacity: opacity);
}
