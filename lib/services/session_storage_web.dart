import 'dart:html' as html;

Future<void> saveString(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<String?> readString(String key) async {
  return html.window.localStorage[key];
}

Future<void> removeKey(String key) async {
  html.window.localStorage.remove(key);
}
