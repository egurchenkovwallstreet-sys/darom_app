import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void hideWebSplash() {
  try {
    final fn = globalContext.getProperty('daromHideSplash'.toJS);
    if (fn != null && fn.isA<JSFunction>()) {
      (fn as JSFunction).callAsFunction();
    }
  } catch (_) {}
}
