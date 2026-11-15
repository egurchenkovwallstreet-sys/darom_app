import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Общие декорации дизайн-системы.
class DaromDecorations {
  DaromDecorations._();

  static const double cardRadius = 20;
  static const double buttonRadius = 16;
  static const double screenPaddingH = 24;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static BoxDecoration glassCard({Color? borderColor}) => BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: (borderColor ?? AppColors.accent).withOpacity(0.18),
          width: 1,
        ),
        boxShadow: softShadow,
      );

  static BoxDecoration solidCard({Color? borderColor}) => BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: (borderColor ?? AppColors.textSecondary).withOpacity(0.12),
        ),
        boxShadow: softShadow,
      );

  static ButtonStyle dangerOutlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.danger, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  /// Текст в полях ввода на светлом фоне — всегда тёмный, не белый.
  static const TextStyle fieldText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle fieldTextLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle fieldHint({double fontSize = 15}) => TextStyle(
        color: AppColors.textSecondary.withOpacity(0.9),
        fontSize: fontSize,
      );

  static OutlineInputBorder fieldOutlineBorder({bool focused = false}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
        borderSide: BorderSide(
          color: focused ? AppColors.accent : AppColors.borderSoft,
          width: focused ? 1.5 : 1,
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
        fillColor: filled ? AppColors.surface.withOpacity(0.95) : null,
        enabledBorder: fieldOutlineBorder(),
        focusedBorder: fieldOutlineBorder(focused: true),
        border: fieldOutlineBorder(),
      );
}