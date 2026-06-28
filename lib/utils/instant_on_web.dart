import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// На Web показываем виджет сразу; на других платформах — с анимацией.
Widget animateUnlessWeb(Widget child, Widget Function(Widget target) animated) {
  if (kIsWeb) return child;
  return animated(child);
}
