/// Общие настройки радиуса поиска объявлений на карте.
class MapRadiusOptions {
  MapRadiusOptions._();

  static const List<double> kmValues = [1, 2, 5, 10, 50];
  static const List<String> labels = ['1 км', '2 км', '5 км', '10 км', 'Весь город'];
  static const List<String> buttonLabels = ['1', '2', '5', '10', 'Город'];

  static double kmAt(int index) => kmValues[index.clamp(0, kmValues.length - 1)];

  static int zoomFor(double radiusKm) => radiusKm <= 2 ? 14 : 12;
}
