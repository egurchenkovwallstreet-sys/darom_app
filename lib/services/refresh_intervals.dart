/// Интервалы автообновления данных с сервера.
///
/// Каждый открытый телефон опрашивает API постоянно: короткие интервалы
/// умножаются на число пользователей и перегружают сервер.
class RefreshIntervals {
  RefreshIntervals._();

  /// Открытый чат — быстрый опрос.
  static const chatsActive = Duration(seconds: 3);

  /// Список чатов на активной вкладке.
  static const chatsList = Duration(seconds: 10);

  /// Фон: другая вкладка или свёрнутое приложение.
  static const chatsBackground = Duration(seconds: 30);

  /// @deprecated Используйте [chatsActive] / [chatsList] / [chatsBackground].
  static const chats = chatsActive;

  static const support = Duration(seconds: 10);
  static const homeListings = Duration(seconds: 30);
  static const categoryListings = Duration(seconds: 20);
}
