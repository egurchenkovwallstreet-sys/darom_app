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

  static const midnightGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkBlue,
      teal,
      cyan,
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
