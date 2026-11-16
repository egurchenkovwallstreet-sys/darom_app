import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';

/// Плотная белая поверхность с мягкой тенью (без рамок, размытия и прозрачности).
///
/// Имя и параметры `blurSigma`, `fillOpacity`, `borderColor`, `borderWidth`
/// сохранены для совместимости и игнорируются.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = DaromDecorations.cardRadius,
    this.blurSigma = 0,
    this.padding,
    this.borderColor,
    this.fillColor,
    this.fillOpacity = 1,
    this.borderWidth = 0,
    this.softShadow = true,
    this.elevatedShadow = false,
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
  final bool elevatedShadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fillColor ?? AppColors.surface,
        borderRadius: radius,
        boxShadow: softShadow || elevatedShadow ? DaromDecorations.cardShadow : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
