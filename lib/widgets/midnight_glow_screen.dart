import 'package:flutter/material.dart';
import '../services/planet_assets.dart';
import '../theme/app_colors.dart';

/// Общий экран с фоном Midnight Glow: градиент + планета (левая часть) + контент.
class MidnightGlowScreen extends StatefulWidget {
  const MidnightGlowScreen({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.showDecorations = true,
    this.lightweight = false,
  });

  final Widget child;
  final Widget? bottomNavigationBar;
  final bool showDecorations;
  /// Без анимации планеты и декораций — для экрана загрузки.
  final bool lightweight;

  @override
  State<MidnightGlowScreen> createState() => _MidnightGlowScreenState();
}

class _MidnightGlowScreenState extends State<MidnightGlowScreen>
    with SingleTickerProviderStateMixin {
  bool _didPrecacheImage = false;
  AnimationController? _planetZoomController;
  Animation<double>? _planetZoom;

  @override
  void initState() {
    super.initState();
    if (!widget.lightweight) {
      final controller = AnimationController(
        vsync: this,
        duration: PlanetAssets.zoomDuration,
      );
      _planetZoomController = controller;
      _planetZoom = Tween<double>(begin: 1.0, end: PlanetAssets.zoomScale).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      controller.forward();
    }
  }

  @override
  void dispose() {
    _planetZoomController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didPrecacheImage && !widget.lightweight) {
      _didPrecacheImage = true;
      precacheImage(const AssetImage(PlanetAssets.path), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F4),
      resizeToAvoidBottomInset: false,
      extendBody: widget.bottomNavigationBar != null,
      bottomNavigationBar: widget.bottomNavigationBar != null
          ? ColoredBox(
              color: Colors.transparent,
              child: widget.bottomNavigationBar,
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            removeTop: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.warmTrustGradient,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.warmTrustOverlay(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _BlurSpot extends StatelessWidget {
  const _BlurSpot({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorIcon extends StatelessWidget {
  const _DecorIcon({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.iconSize,
    required this.icon,
    required this.color,
    required this.shadowOpacity,
    required this.iconOpacity,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final double iconSize;
  final IconData icon;
  final Color color;
  final double shadowOpacity;
  final double iconOpacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(shadowOpacity),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: color.withOpacity(iconOpacity),
        ),
      ),
    );
  }
}
