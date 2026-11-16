import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';

/// Единая иконка-шапка для экранов приветствия, входа и регистрации.
class AuthHeaderIcon extends StatelessWidget {
  const AuthHeaderIcon(this.icon, {super.key, this.size = 88});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: DaromDecorations.cardShadow,
      ),
      child: Icon(icon, size: size * 0.46, color: AppColors.white),
    );
  }
}
