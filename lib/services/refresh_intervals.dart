/// Интервалы автообновления данных с сервера.
class RefreshIntervals {
  RefreshIntervals._();

  static const chats = Duration(seconds: 1);
  static const support = Duration(seconds: 3);
  static const homeListings = Duration(seconds: 5);
  static const categoryListings = Duration(seconds: 2);
}
