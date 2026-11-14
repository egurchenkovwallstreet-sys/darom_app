import 'package:flutter/material.dart';

/// Цветовая палитра Midnight Glow (ТЗ v3.0)
class AppColors {
  AppColors._();

  static const darkBlue = Color(0xFF001F3F);
  static const teal = Color(0xFF008C8C);
  static const cyan = Color(0xFF00BFFF);
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFFFC107);
  static const red = Color(0xFFFF5722);
  /// Цвет иконок категорий и подкатегорий (как «Спорт» на главном экране).
  static const categoryIcon = Color(0xFF2196F3);

  static const midnightGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkBlue,
      teal,
      cyan,
    ],
  );

  /// Мягкий тёплый фон (домашний экран / оболочка).
  static const warmTrustGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF9F4),
      Color(0xFFFFECD9),
      Color(0xFFF5DFC8),
    ],
  );

  static LinearGradient warmTrustOverlay({double opacity = 1.0}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFFEFC).withOpacity(0.55 * opacity),
          const Color(0xFFFFE8D6).withOpacity(0.35 * opacity),
          const Color(0xFFFAD9BE).withOpacity(0.25 * opacity),
        ],
      );

  static LinearGradient overlayGradient({double opacity = 1.0}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkBlue.withOpacity(0.7 * opacity),
          teal.withOpacity(0.3 * opacity),
          cyan.withOpacity(0.2 * opacity),
        ],
      );
}
