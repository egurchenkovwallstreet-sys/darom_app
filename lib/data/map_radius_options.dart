/// Общие настройки радиуса поиска объявлений на карте.
class MapRadiusOptions {
  MapRadiusOptions._();

  static const int allListingsIndex = 4;

  static const List<double> kmValues = [1, 2, 5, 10, 50];
  static const List<String> labels = ['1 км', '2 км', '5 км', '10 км', 'Все объявления'];
  static const List<String> buttonLabels = ['1', '2', '5', '10', 'Все объявления'];

  static bool isAllListings(int index) => index == allListingsIndex;

  static double kmAt(int index) => kmValues[index.clamp(0, kmValues.length - 1)];

  static int zoomForIndex(int index) {
    if (isAllListings(index)) return 4;
    return zoomFor(kmAt(index));
  }

  static int zoomFor(double radiusKm) => radiusKm <= 2 ? 14 : 12;
}
