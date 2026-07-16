import 'dart:js_interop';

@JS('daromHideSplash')
external void _daromHideSplash();

void hideWebSplash() {
  try {
    _daromHideSplash();
  } catch (_) {}
}
