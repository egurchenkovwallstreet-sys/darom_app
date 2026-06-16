import 'package:flutter/services.dart';

/// Предзагрузка earth.png до первого кадра — убирает паузу 2–3 с на web.
class PlanetAssets {
  PlanetAssets._();

  static const path = 'assets/images/earth.png';
  static bool isPreloaded = false;

  static Future<void> preload() async {
    if (isPreloaded) return;
    await rootBundle.load(path);
    isPreloaded = true;
  }
}
