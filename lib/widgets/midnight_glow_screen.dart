import 'package:flutter/material.dart';
import '../services/planet_assets.dart';
import '../theme/app_colors.dart';

/// Общий экран с фоном Midnight Glow.
/// С первого кадра — тёмный градиент, затем планета, потом контент.
class MidnightGlowScreen extends StatefulWidget {
  const MidnightGlowScreen({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.showDecorations = true,
    /// true — для чатов и форм: поле ввода поднимается над клавиатурой.
    this.adjustForKeyboard = false,
  });

  final Widget child;
  final Widget? bottomNavigationBar;
  final bool showDecorations;
  final bool adjustForKeyboard;

  @override
  State<MidnightGlowScreen> createState() => _MidnightGlowScreenState();
}

class _MidnightGlowScreenState extends State<MidnightGlowScreen>
    with TickerProviderStateMixin {
  late AnimationController _planetController;
  late Animation<double> _planetScale;
  late AnimationController _contentFadeController;
  late Animation<double> _contentFade;
  bool _didPrecacheImage = false;

  @override
  void initState() {
    super.initState();

    _planetController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..forward();

    _planetScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _planetController, curve: Curves.easeInOut),
    );

    // Планета без fade — видна сразу. Контент появляется чуть позже.
    _contentFadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentFadeController, curve: Curves.easeIn),
    );

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _contentFadeController.forward();
    });
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
  void dispose() {
    _planetController.dispose();
    _contentFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: widget.adjustForKeyboard,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Фон без учёта клавиатуры — всегда на весь экран.
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
                _PlanetLayer(planetScale: _planetScale),
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

          FadeTransition(
            opacity: _contentFade,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _PlanetLayer extends StatelessWidget {
  const _PlanetLayer({required this.planetScale});

  final Animation<double> planetScale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: planetScale,
      builder: (context, child) {
        return Positioned.fill(
          child: Transform.scale(
            scale: planetScale.value,
            alignment: PlanetAssets.scaleAlignment,
            child: child,
          ),
        );
      },
      child: Image.asset(
        PlanetAssets.path,
        fit: BoxFit.cover,
        alignment: PlanetAssets.alignment,
        gaplessPlayback: true,
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
