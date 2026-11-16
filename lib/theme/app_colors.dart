import 'package:flutter/material.dart';

/// Дизайн-система «Даром» — Deep Blue: холодный светлый фон, белые поверхности, глубокий синий акцент.
class AppColors {
  AppColors._();

  // --- Design tokens ---
  static const background = Color(0xFFF3F6FA);
  static const backgroundStart = background;
  static const backgroundEnd = background;
  static const backgroundWarm = background;
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGlass = surface;

  static const primary = Color(0xFF1B4B8F);
  static const primaryDark = Color(0xFF0F2F5C);
  static const primarySoft = Color(0xFFE6EEF8);
  static const secondary = primary;

  static const textPrimary = Color(0xFF0F1B2D);
  static const textSecondary = Color(0xFF55657A);
  static const borderSoft = Color(0x00000000);
  static const borderDivider = Color(0xFFE9EEF4);
  static const glassHighlight = surface;
  static const glassBorder = Color(0x00000000);

  /// Обводка пустого чекбокса / радиокнопки — должна быть видна на белом.
  static const controlOutline = Color(0xFF8A99AD);

  static const tabTrack = Color(0xFFE6ECF3);
  static const navActiveTint = primarySoft;
  static const chipSelected = primary;

  static const badgeFounderBg = Color(0xFFF3EAD3);
  static const badgeFounderText = Color(0xFF5C4A23);
  static const badgeNewbieBg = primarySoft;
  static const badgeNewbieText = primary;

  /// Ошибки и удаление: приглушённый терракотовый (яркий красный в продукте запрещён).
  static const danger = Color(0xFF9A4A3C);
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
