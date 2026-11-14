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
}