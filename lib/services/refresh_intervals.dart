/// Интервалы автообновления данных с сервера.
class RefreshIntervals {
  RefreshIntervals._();

  /// Открытый чат — быстрый опрос.
  static const chatsActive = Duration(seconds: 1);

  /// Список чатов на активной вкладке.
  static const chatsList = Duration(seconds: 3);

  /// Фон: другая вкладка или свёрнутое приложение.
  static const chatsBackground = Duration(seconds: 5);

  /// @deprecated Используйте [chatsActive] / [chatsList] / [chatsBackground].
  static const chats = chatsActive;

  static const support = Duration(seconds: 3);
  static const homeListings = Duration(seconds: 5);
  static const categoryListings = Duration(seconds: 2);
}
