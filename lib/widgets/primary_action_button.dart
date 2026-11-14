import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';

/// Основная кнопка: изумрудный акцент, мягкая тень, scale при нажатии.
class PrimaryActionButton extends StatefulWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.padding = EdgeInsets.zero,
    this.gradientColors,
    this.shadowColor,
    this.height = 60,
    this.fontSize = 20,
    this.borderRadius = DaromDecorations.buttonRadius,
    this.icon,
    this.showShadow = true,
  });

  static const primaryGradient = [
    AppColors.accent,
    AppColors.accentDark,
  ];

  static const primaryShortGradient = primaryGradient;

  static const successGradient = [
    AppColors.accent,
    AppColors.accentDark,
  ];

  static const warningGradient = [
    AppColors.accentSecondary,
    Color(0xFFFBBF24),
  ];

  static const dangerGradient = [
    AppColors.danger,
    Color(0xFFFCA5A5),
  ];

  static const dangerDeepGradient = dangerGradient;

  static const tealGradient = primaryGradient;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;
  final Color? shadowColor;
  final double height;
  final double fontSize;
  final double borderRadius;
  final IconData? icon;
  final bool showShadow;

  @override
  State<PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<PrimaryActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || widget.loading) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !widget.loading && widget.onPressed != null;
    final colors = widget.gradientColors ?? PrimaryActionButton.primaryGradient;
    final glowColor = widget.shadowColor ?? colors.first;

    return Padding(
      padding: widget.padding,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) {
          _setPressed(false);
          if (canTap) widget.onPressed!();
        },
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed && canTap ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.55,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.showShadow
                    ? [
                        BoxShadow(
                          color: glowColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: _gradientButtonFace(colors),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientButtonFace(List<Color> colors) {
    final face = Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(
          color: const Color(0xFF000000).withOpacity(0.15),
          width: 2,
        ),
      ),
      child: Center(
        child: widget.loading
            ? SizedBox(
                width: widget.height * 0.45,
                height: widget.height * 0.45,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: widget.fontSize),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0x4D000000),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    if (kIsWeb) return face;

    return face
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 2.seconds,
          color: AppColors.textPrimary.withOpacity(0.3),
        );
  }
}
