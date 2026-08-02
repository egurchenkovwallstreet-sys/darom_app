import 'package:flutter/material.dart';

import 'session_storage.dart';

/// Сохранённый язык интерфейса (ru / en). Юридические документы остаются на русском.
class LocaleService extends ChangeNotifier {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const _keyLocale = 'app_locale_v1';
  static const _keyChosen = 'app_locale_chosen_v1';

  Locale _locale = const Locale('ru');
  bool _hasChosenLocale = false;
  bool _loaded = false;

  Locale get locale => _locale;
  bool get hasChosenLocale => _hasChosenLocale;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final code = await readString(_keyLocale);
    _hasChosenLocale = await readString(_keyChosen) == '1';
    if (code == 'en' || code == 'ru') {
      _locale = Locale(code);
    }
    _loaded = true;
    notifyListeners();
  }

  /// Для пользователей, которые уже были в приложении до добавления языка.
  Future<void> ensureDefaultForExistingUser() async {
    if (_hasChosenLocale) return;
    _locale = const Locale('ru');
    _hasChosenLocale = true;
    await saveString(_keyLocale, 'ru');
    await saveString(_keyChosen, '1');
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (code != 'ru' && code != 'en') return;
    _locale = Locale(code);
    _hasChosenLocale = true;
    await saveString(_keyLocale, code);
    await saveString(_keyChosen, '1');
    notifyListeners();
  }

  String get languageLabel {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      default:
        return 'Русский';
    }
  }
}
