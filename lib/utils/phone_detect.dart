/// Обнаружение номера телефона в тексте (как на сервере).
bool containsPhoneNumber(String text) {
  final patterns = [
    RegExp(r'(?:\+7|8|7)[\s(–-]*\d{3}[\s)–-]*\d{3}[\s–-]*\d{2}[\s–-]*\d{2}'),
    RegExp(r'\b9\d{2}[\s–-]?\d{3}[\s–-]?\d{2}[\s–-]?\d{2}\b'),
    RegExp(r'\b\d{10,11}\b'),
  ];

  for (final pattern in patterns) {
    if (pattern.hasMatch(text)) return true;
  }
  return false;
}
