import 'package:flutter/material.dart';

import '../utils/responsive_layout.dart';

/// На десктопе ограничивает ширину контента и центрирует; на телефоне — без изменений.
class ResponsivePageFrame extends StatelessWidget {
  const ResponsivePageFrame({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isDesktop(context)) {
      return child;
    }

    final width = maxWidth ?? ResponsiveLayout.contentMaxWidth(context);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}
