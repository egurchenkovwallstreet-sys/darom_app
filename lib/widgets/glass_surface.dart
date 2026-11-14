import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';

/// Полупрозрачная «стеклянная» панель с размытием фона.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = DaromDecorations.cardRadius,
    this.blurSigma = 12,
    this.padding,
    this.borderColor,
    this.fillColor,
    this.fillOpacity = 0.8,
    this.borderWidth = 1,
    this.softShadow = true,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? fillColor;
  final double fillOpacity;
  final double borderWidth;
  final bool softShadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final fill = fillColor ?? AppColors.surface;
    final border = borderColor ?? AppColors.textSecondary;

    Widget panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: fill.withOpacity(fillOpacity),
            border: Border.all(color: border.withOpacity(0.15), width: borderWidth),
          ),
          child: padding != null ? Padding(padding: padding!, child: child) : child,
        ),
      ),
    );

    if (!softShadow) return panel;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: DaromDecorations.softShadow,
      ),
      child: panel,
    );
  }
}