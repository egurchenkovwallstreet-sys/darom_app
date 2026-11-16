import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Общий каркас экрана: ровный кремовый фон + контент + (опционально) нижнее меню.
class MidnightGlowScreen extends StatelessWidget {
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
  final bool lightweight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      extendBody: bottomNavigationBar != null,
      bottomNavigationBar: bottomNavigationBar != null
          ? ColoredBox(
              color: Colors.transparent,
              child: bottomNavigationBar,
            )
          : null,
      body: child,
    );
  }
}
