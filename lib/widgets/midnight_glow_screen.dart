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
  });

  final Widget child;
  final Widget? bottomNavigationBar;
  final bool showDecorations;

  @override
  State<MidnightGlowScreen> createState() => _MidnightGlowScreenState();
}

class _MidnightGlowScreenState extends State<MidnightGlowScreen>
    with SingleTickerProviderStateMixin {
  bool _didPrecacheImage = false;
  late final AnimationController _planetZoomController;
  late final Animation<double> _planetZoom;

  @override
  void initState() {
    super.initState();
    _planetZoomController = AnimationController(
      vsync: this,
      duration: PlanetAssets.zoomDuration,
    );
    _planetZoom = Tween<double>(begin: 1.0, end: PlanetAssets.zoomScale).animate(
      CurvedAnimation(parent: _planetZoomController, curve: Curves.easeOut),
    );
    _planetZoomController.forward();
  }

  @override
  void dispose() {
    _planetZoomController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didPrecacheImage) {
      _didPrecacheImage = true;
      precacheImage(const AssetImage(PlanetAssets.path), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: widget.bottomNavigationBar,
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
                      gradient: AppColors.midnightGlowGradient,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _planetZoom,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _planetZoom.value,
                          alignment: PlanetAssets.alignment,
                          child: child,
                        );
                      },
                      child: const Image(
                        image: AssetImage(PlanetAssets.path),
                        fit: BoxFit.cover,
                        alignment: PlanetAssets.alignment,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.overlayGradient(),
                    ),
                  ),
                ),
                const _BlurSpot(top: -100, right: -100, size: 400, color: AppColors.cyan, opacity: 0.3),
                const _BlurSpot(bottom: -150, left: -150, size: 500, color: AppColors.teal, opacity: 0.4),
                if (widget.showDecorations) ...[
                  const _DecorIcon(
                    top: 50,
                    right: 80,
                    size: 120,
                    iconSize: 100,
                    icon: Icons.favorite,
                    color: AppColors.cyan,
                    shadowOpacity: 0.3,
                    iconOpacity: 0.2,
                  ),
                  const _DecorIcon(
                    bottom: 200,
                    left: 50,
                    size: 100,
                    iconSize: 80,
                    icon: Icons.favorite,
                    color: AppColors.teal,
                    shadowOpacity: 0.3,
                    iconOpacity: 0.2,
                  ),
                  const _DecorIcon(
                    top: 300,
                    right: 30,
                    size: 140,
                    iconSize: 110,
                    icon: Icons.handshake,
                    color: AppColors.cyan,
                    shadowOpacity: 0.25,
                    iconOpacity: 0.18,
                  ),
                ],
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
