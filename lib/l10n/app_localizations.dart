import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('ru'), Locale('en')];

  bool get isEn => locale.languageCode == 'en';

  String _t(String ru, String en) => isEn ? en : ru;

  // App / language
  String get appTitle => _t('Даром', 'Darom');
  String get languageTitle => _t('Язык', 'Language');
  String get languageWelcomeTitle => _t('Выберите язык', 'Choose language');
  String get languageWelcomeSubtitle =>
      _t('Можно изменить позже в профиле', 'You can change it later in Profile');
  String get languageRussian => 'Русский';
  String get languageEnglish => 'English';
  String get continueButton => _t('Продолжить', 'Continue');

  // Bottom nav
  String get navHome => _t('Главная', 'Home');
  String get navFavorites => _t('Избранное', 'Favorites');
  String get navAdd => _t('Добавить', 'Add');
  String get navAddListing => _t('Добавить\nобъявление', 'Add\nlisting');
  String get navChats => _t('Чаты', 'Chats');
  String get navProfile => _t('Профиль', 'Profile');

  // Onboarding
  String get onboardingTitle1 =>
      _t('Добро начинается с одной вещи', 'It starts with one item');
  String get onboardingDesc1 => _t(
        'В каждом доме лежит то, что может обрадовать другого человека — «Даром» делает такой жест простым и близким.',
        'Every home has something that could make someone else happy — Darom makes sharing simple and personal.',
      );
  String get onboardingTitle2 =>
      _t('Помогать — проще, чем кажется', 'Helping is easier than you think');
  String get onboardingDesc2 => _t(
        'Не нужно быть богатым или искать, куда нести вещи: достаточно одного доброго «возьмите, пусть послужит» — и вы уже меняете чей-то день.',
        'You do not need to be rich or find a drop-off point — one kind “take it, make use of it” can brighten someone’s day.',
      );
  String get onboardingTitle3 =>
      _t('Подарите радость — она рядом', 'Give joy — it is close by');
  String get onboardingDesc3 => _t(
        'Отдайте лишнее или заберите нужное у соседа — бесплатно, по-человечески, и мир станет чуть теплее.',
        'Give away what you do not need or pick up what a neighbor offers — free, human, and a little warmer world.',
      );
  String get nextButton => _t('Далее', 'Next');
  String get startButton => _t('Начать', 'Get started');
  String get partnerLink => _t('Я партнёр / блогер', 'I am a partner / blogger');

  // Phone / auth
  String get phoneTitle => _t('Введите номер телефона', 'Enter phone number');
  String get phoneCompactSubtitle => _t(
        'Введите реальный номер и нажмите «Продолжить»',
        'Enter your real number and tap Continue',
      );
  String get phoneHint => _t('Номер телефона', 'Phone number');
  String get errAcceptOffer =>
      _t('Примите условия оферты, чтобы продолжить', 'Accept the terms of service to continue');
  String get errAcceptPrivacy => _t(
        'Дайте согласие на обработку персональных данных',
        'Consent to personal data processing is required',
      );
  String get errInvalidPhone => _t('Введите корректный номер', 'Enter a valid phone number');
  String get phoneWarningLine1 => _t(
        'Укажите свой настоящий номер — тот, которым вы пользуетесь сейчас.\n',
        'Use your real current phone number.\n',
      );
  String get phoneWarningLine2 => _t(
        'При первом объявлении или сообщении в чате может потребоваться бесплатное подтверждение номера.\n',
        'Your first listing or chat message may require free phone verification.\n',
      );
  String get phoneWarningLine3 => _t(
        '⚠️ Если указать чужой или неактуальный номер, восстановить доступ к аккаунту может быть невозможно.',
        '⚠️ Using someone else’s or outdated number may make account recovery impossible.',
      );

  // PIN
  String get errPinFourDigits => _t('Введите 4 цифры пароля', 'Enter 4-digit PIN');
  String get pinTitle => _t('Введите пароль', 'Enter password');
  String get pinSubtitle => _t(
        '4 цифры, которые вы задали при регистрации',
        '4 digits you set during registration',
      );
  String get pinCompactSubtitle => _t('4 цифры для входа', '4 digits to sign in');
  String get showPinDigits => _t('Показать цифры', 'Show digits');
  String get hidePinDigits => _t('Скрыть цифры', 'Hide digits');
  String get loginButton => _t('Войти', 'Log in');
  String get forgotPinReset => _t(
        'Забыли пароль? Подтвердить номер',
        'Forgot password? Verify phone',
      );
  String get forgotPin => _t('Забыли PIN?', 'Forgot PIN?');

  // Home
  String get searchHint => _t('Поиск: название или описание...', 'Search: title or description...');
  String get searchMinChars => _t('Введите минимум 2 символа', 'Enter at least 2 characters');
  String searchNothingFound(String query) =>
      _t('По запросу «$query» ничего не найдено', 'Nothing found for “$query”');
  String searchFoundCount(int n) => _t('Найдено: $n', 'Found: $n');
  String get tabMap => _t('🗺️ Карта', '🗺️ Map');
  String get tabList => _t('📋 Список', '📋 List');
  String get radiusLabel => _t('Радиус:', 'Radius:');
  String get categories => _t('Категории', 'Categories');
  String get repeatButton => _t('Повторить', 'Retry');
  String get openButton => _t('Открыть', 'Open');
  String get loadingLocation => _t('Определяем местоположение...', 'Detecting location...');
  String get loadingListings => _t('Загружаем объявления рядом...', 'Loading nearby listings...');
  String get noListingsOnMap => _t('Объявлений на карте пока нет', 'No listings on the map yet');
  String noListingsInRadius(String radius) =>
      _t('В радиусе $radius объявлений нет', 'No listings within $radius');
  String get locationDenied => _t(
        'Разрешите доступ к геолокации в браузере — пока показан центр Москвы',
        'Allow location in the browser — showing Moscow center for now',
      );
  String get locationNotSecure => _t(
        'Геолокация работает только по HTTPS — показан центр Москвы',
        'Location works only over HTTPS — showing Moscow center',
      );
  String get locationTimeout => _t(
        'Не удалось определить местоположение — показан центр Москвы',
        'Could not detect location — showing Moscow center',
      );
  String get locationUnavailable => _t(
        'Геолокация недоступна — показан центр Москвы',
        'Location unavailable — showing Moscow center',
      );
  String get listingsCountSuffix => _t('шт.', 'items');

  // Privacy re-consent
  String get privacyUpdateTitle =>
      _t('Обновилась политика ПДн', 'Privacy policy updated');
  String privacyUpdateBody(String date) => _t(
        'Оператор обновил политику обработки персональных данных (ред. $date). '
            'Ознакомьтесь с документами и подтвердите согласие, чтобы продолжить пользоваться сервисом.',
        'The privacy policy was updated ($date). '
            'Please read the documents and confirm to keep using the service.',
      );
  String get privacyPolicyLink => _t('Политика ПДн', 'Privacy policy');
  String get cookiePolicyLink => _t('Политика cookie', 'Cookie policy');
  String get acceptButton => _t('Принимаю', 'I accept');
  String get logoutButton => _t('Выйти из аккаунта', 'Log out');
  String get privacyConsentSaved =>
      _t('Согласие на обработку ПДн сохранено', 'Privacy consent saved');
  String get errPrivacyConsentSave =>
      _t('Не удалось сохранить согласие', 'Could not save consent');

  // Legal checkboxes (UI only)
  String get offerCheckboxLabel => _t(
        'Принимаю условия пользовательского соглашения (оферты)',
        'I accept the terms of service (public offer)',
      );
  String get readOfferLink => _t('Читать оферту', 'Read offer');
  String privacyCheckboxLabel(String version) => _t(
        'Даю согласие на обработку персональных данных (ред. $version)',
        'I consent to personal data processing (rev. $version)',
      );
  String get readPrivacyLink => _t('Политика ПДн', 'Privacy policy');

  // Profile settings
  String get myListings => _t('Мои объявления', 'My listings');
  String get partnerStats => _t('Статистика партнёра', 'Partner stats');
  String get adminPanel => _t('Админ-панель', 'Admin panel');
  String get adminReports => _t('Отчёты', 'Reports');
  String get adminDailyReports => _t('Ежедневные отчёты', 'Daily reports');
  String get support => _t('Служба поддержки', 'Support');
  String get aboutApp => _t('О приложении', 'About');
  String get publicOffer => _t('Пользовательское соглашение', 'Terms of service');
  String get privacyPolicyMenu => _t('Политика персональных данных', 'Privacy policy');
  String get cookiePolicyMenu => _t('Политика cookie', 'Cookie policy');
  String get myPersonalData => _t('Мои персональные данные', 'My personal data');
  String get logoutProfile => _t('Выйти', 'Log out');
  String get deleteAccount => _t('Удалить аккаунт', 'Delete account');
  String get editProfile => _t('Редактировать', 'Edit');
  String get settingsSection => _t('Настройки', 'Settings');
  String get languageChanged => _t('Язык изменён', 'Language changed');

  // Profile
  String get profileTitle => _t('Профиль', 'Profile');
  String get tapPhotoToChange =>
      _t('Нажмите на фото, чтобы сменить', 'Tap photo to change');
  String get founderBadge => _t('⭐ Основатель', '⭐ Founder');
  String get partnerBadge => _t('🤝 Партнёр', '🤝 Partner');
  String get statListings => _t('Объявления', 'Listings');
  String get statDeals => _t('Сделки', 'Deals');
  String get statPickups => _t('Заборы', 'Pickups');
  String get achievementsTitle => _t('🏆 Достижения', '🏆 Achievements');
  String get errNoPhone => _t('Нет номера телефона', 'No phone number');
  String get avatarUpdated => _t('Аватар обновлён', 'Avatar updated');
  String get deleteAccountTitle => _t('Удалить аккаунт?', 'Delete account?');
  String get deleteAccountBody => _t(
        'Будут удалены профиль, объявления, чаты и другие персональные данные. '
            'Это действие необратимо.',
        'Your profile, listings, chats and other personal data will be deleted. '
            'This cannot be undone.',
      );
  String get deleteButton => _t('Удалить', 'Delete');
  String get errLoadProfile =>
      _t('Не удалось загрузить профиль', 'Could not load profile');
  String get logoutAndLoginAgain =>
      _t('Выйти и войти заново', 'Log out and sign in again');
  String get editProfileSoon =>
      _t('Редактировать профиль', 'Edit profile');
  String get adminUserRequests =>
      _t('Обращения пользователей', 'User requests');
  String get adminDailyStats =>
      _t('Ежедневная статистика', 'Daily statistics');
  String comingSoon(String title) => _t('$title — скоро', '$title — coming soon');

  String donorLevelLabel(String level) {
    final normalized = level.toLowerCase();
    if (normalized.contains('нович')) return _t('Новичок', 'Novice');
    if (normalized.contains('актив')) return _t('Активный', 'Active');
    if (normalized.contains('щедр')) return _t('Щедрый', 'Generous');
    if (normalized.contains('благот')) return _t('Благотворитель', 'Philanthropist');
    if (normalized.contains('добр') || normalized.contains('сердц')) {
      return _t('Самое доброе сердце', 'Kindest heart');
    }
    return level;
  }

  String achievementTitle(String ruTitle) {
    switch (ruTitle) {
      case 'Новичок':
        return _t('Новичок', 'Novice');
      case 'Активный':
        return _t('Активный', 'Active');
      case 'Щедрый':
        return _t('Щедрый', 'Generous');
      case 'Благотворитель':
        return _t('Благотворитель', 'Philanthropist');
      case 'Самое доброе сердце':
        return _t('Самое доброе сердце', 'Kindest heart');
      default:
        return ruTitle;
    }
  }

  // Categories screen
  String subcategoriesCount(int n) {
    if (isEn) return n == 1 ? '1 subcategory' : '$n subcategories';
    return '$n подкатегорий';
  }

  String listingsCountLabel(int count) {
    if (isEn) {
      return count == 1 ? '1 listing' : '$count listings';
    }
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return '$count объявление';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return '$count объявления';
    }
    return '$count объявлений';
  }

  // Home errors
  String get errSearchBackend =>
      _t('Ошибка поиска — проверьте backend', 'Search error — check backend');
  String get errServerConnection => _t(
        'Не удалось связаться с сервером. Проверьте интернет или откройте https://darom-app.online/',
        'Could not reach the server. Check your connection or open https://darom-app.online/',
      );

  // Common
  String get cancel => _t('Отмена', 'Cancel');
  String get loading => _t('Загрузка...', 'Loading...');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ru' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
