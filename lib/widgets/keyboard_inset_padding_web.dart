import 'dart:html' as html;
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Мобильный web: высота клавиатуры через visualViewport (MediaQuery часто = 0).
class KeyboardInsetPadding extends StatefulWidget {
  const KeyboardInsetPadding({super.key, required this.child});

  final Widget child;

  @override
  State<KeyboardInsetPadding> createState() => _KeyboardInsetPaddingState();
}

class _KeyboardInsetPaddingState extends State<KeyboardInsetPadding> {
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _syncKeyboardHeight();
    html.window.visualViewport?.addEventListener('resize', _onViewportEvent);
    html.window.visualViewport?.addEventListener('scroll', _onViewportEvent);
    html.window.addEventListener('resize', _onViewportEvent);
    html.document.addEventListener('focusin', _onViewportEvent);
    html.document.addEventListener('focusout', _onFocusOut);
  }

  @override
  void dispose() {
    html.window.visualViewport?.removeEventListener('resize', _onViewportEvent);
    html.window.visualViewport?.removeEventListener('scroll', _onViewportEvent);
    html.window.removeEventListener('resize', _onViewportEvent);
    html.document.removeEventListener('focusin', _onViewportEvent);
    html.document.removeEventListener('focusout', _onFocusOut);
    super.dispose();
  }

  void _onViewportEvent(html.Event _) => _syncKeyboardHeight();

  void _onFocusOut(html.Event _) {
    Future<void>.delayed(const Duration(milliseconds: 150), _syncKeyboardHeight);
  }

  void _syncKeyboardHeight() {
    final viewport = html.window.visualViewport;
    final layoutHeight = html.window.innerHeight?.toDouble();
    if (viewport == null || layoutHeight == null) return;

    final visibleBottom = viewport.offsetTop + viewport.height!;
    final height = math.max(0.0, layoutHeight - visibleBottom);

    if ((height - _keyboardHeight).abs() > 1 && mounted) {
      setState(() => _keyboardHeight = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = math.max(_keyboardHeight, MediaQuery.viewInsetsOf(context).bottom);
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: inset),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}
