{{flutter_js}}
{{flutter_build_config}}

// Без service worker: он на первом визите задерживает старт до 4 с и повторно качает main.dart.js.
_flutter.loader.load();
