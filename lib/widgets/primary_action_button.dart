import 'package:flutter/material.dart';

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
    AppColors.primaryLight,
    AppColors.primaryDark,
  ];

  static const primaryShortGradient = primaryGradient;

  static const successGradient = primaryGradient;

  static const warningGradient = primaryGradient;

  static const dangerGradient = [
    AppColors.danger,
    AppColors.danger,
  ];

  static const dangerDeepGradient = dangerGradient;

  /// Белая кнопка с графитовым текстом — для второстепенных действий.
  static const neutralGradient = [
    AppColors.surface,
    AppColors.surface,
  ];

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
          scale: _pressed && canTap ? 0.98 : 1.0,
          duration: DaromDecorations.interactionDuration,
          curve: DaromDecorations.interactionCurve,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.55,
            child: Container(
              width: double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: colors.first,
                gradient: colors.length > 1 && colors.first != colors.last
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      )
                    : null,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.showShadow ? DaromDecorations.cardShadow : null,
              ),
              child: _buttonFace(colors.last),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buttonFace(Color background) {
    final foreground =
        background.computeLuminance() > 0.6 ? AppColors.textPrimary : AppColors.white;

    return Center(
      child: widget.loading
          ? SizedBox(
              width: widget.height * 0.45,
              height: widget.height * 0.45,
              child: CircularProgressIndicator(
                color: foreground,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: foreground, size: widget.fontSize),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.01,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
