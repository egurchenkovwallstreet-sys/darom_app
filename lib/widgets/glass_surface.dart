import 'dart:ui';

import 'package:flutter/material.dart';

/// Полупрозрачная «стеклянная» панель с размытием фона.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blurSigma = 14,
    this.padding,
    this.borderColor,
    this.fillColor,
    this.fillOpacity = 0.28,
    this.borderWidth = 1.2,
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
    final fill = fillColor ?? const Color(0xFF001F3F);
    final border = borderColor ?? const Color(0xFF00BFFF);

    Widget panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: fill.withOpacity(fillOpacity),
            border: Border.all(color: border.withOpacity(0.42), width: borderWidth),
          ),
          child: padding != null ? Padding(padding: padding!, child: child) : child,
        ),
      ),
    );

    if (!softShadow) return panel;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: panel,
    );
  }
}