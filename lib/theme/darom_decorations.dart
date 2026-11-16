import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Общие декорации дизайн-системы.
class DaromDecorations {
  DaromDecorations._();

  static const double cardRadius = 20;
  static const double buttonRadius = 12;
  static const double inputRadius = 12;
  static const double navBarRadius = 24;
  static const double screenPaddingH = 16;

  static const Duration interactionDuration = Duration(milliseconds: 200);
  static const Curve interactionCurve = Curves.easeOut;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get fabShadow => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => cardShadow;

  static const double glassBlurSigma = 18;
  static const double glassFillOpacity = 0.88;

  static BoxDecoration glassCard({Color? borderColor}) => BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: cardShadow,
      );

  static BoxDecoration warmGlassPanel({double radius = cardRadius}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder, width: 1),
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
        side: BorderSide(color: AppColors.danger.withOpacity(0.35), width: 1),
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
        borderSide: BorderSide(
          color: focused ? AppColors.primary.withOpacity(0.35) : Colors.transparent,
          width: focused ? 1.5 : 0,
        ),
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