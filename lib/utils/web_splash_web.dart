import 'dart:html' as html;

void hideWebSplash() {
  try {
    html.window.callMethod('daromHideSplash');
  } catch (_) {}
}
