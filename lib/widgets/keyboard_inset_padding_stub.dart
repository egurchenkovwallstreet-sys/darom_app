import 'package:flutter/material.dart';

/// На ПК и в приложениях — стандартный отступ MediaQuery.
class KeyboardInsetPadding extends StatelessWidget {
  const KeyboardInsetPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: inset),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: child,
    );
  }
}

/// На ПК — overlap из MediaQuery.
class KeyboardOverlapBuilder extends StatelessWidget {
  const KeyboardOverlapBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, double overlap) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, MediaQuery.viewInsetsOf(context).bottom);
  }
}
