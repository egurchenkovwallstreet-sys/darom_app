import 'package:flutter/material.dart';

/// Адаптация под десктоп: на узких экранах (телефон) поведение не меняется.
class ResponsiveLayout {
  ResponsiveLayout._();

  /// Ширина «телефон / планшет портрет» — ниже этого порога мобильная вёрстка.
  static const double desktopBreakpoint = 900;

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  static bool isWideDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1200;
  }

  static double contentMaxWidth(BuildContext context) {
    if (!isDesktop(context)) return double.infinity;
    return isWideDesktop(context) ? 1120 : 960;
  }

  static double authFormMaxWidth(BuildContext context) {
    if (!isDesktop(context)) return double.infinity;
    return 460;
  }

}
