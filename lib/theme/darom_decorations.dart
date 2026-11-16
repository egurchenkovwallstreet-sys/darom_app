import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Общие декорации дизайн-системы.
class DaromDecorations {
  DaromDecorations._();

  static const double cardRadius = 16;
  static const double buttonRadius = 12;
  static const double inputRadius = 12;
  static const double pillRadius = 100;
  static const double navBarRadius = 24;
  static const double screenPaddingH = 16;

  static const Duration interactionDuration = Duration(milliseconds: 200);
  static const Curve interactionCurve = Curves.easeOut;

  /// Единственная тень в продукте: 0 4px 20px rgba(0,0,0,0.04).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> fabShadow = cardShadow;
  static const List<BoxShadow> elevatedShadow = cardShadow;
  static const List<BoxShadow> softShadow = cardShadow;

  static const double glassBlurSigma = 0;
  static const double glassFillOpacity = 1;

  static BoxDecoration glassCard({Color? borderColor}) => solidCard();

  static BoxDecoration warmGlassPanel({double radius = cardRadius}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cardShadow,
      );

  static BoxDecoration solidCard({Color? borderColor}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: cardShadow,
      );

  static ButtonStyle dangerOutlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        backgroundColor: AppColors.surface,
        side: BorderSide.none,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  static const TextStyle fieldText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.01,
  );

  static const TextStyle fieldTextLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.02,
  );

  static TextStyle fieldHint({double fontSize = 15}) => TextStyle(
        color: AppColors.textSecondary,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
      );

  static TextStyle titleStyle({double fontSize = 22}) => TextStyle(
        color: AppColors.textPrimary,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
      );

  static OutlineInputBorder fieldOutlineBorder({bool focused = false}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide.none,
      );

  static InputDecoration lightFieldDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    bool filled = true,
  }) =>
      InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: fieldHint(),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: prefixIcon,
        filled: filled,
        fillColor: filled ? AppColors.surface : null,
        enabledBorder: fieldOutlineBorder(),
        focusedBorder: fieldOutlineBorder(focused: true),
        border: fieldOutlineBorder(),
      );
}