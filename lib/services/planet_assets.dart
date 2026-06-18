import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Планета на фоне — одна настройка для всего приложения.
class PlanetAssets {
  PlanetAssets._();

  static const path = 'assets/images/earth.png';

  /// Левая часть изображения (не центр).
  static const alignment = Alignment(-1.0, 0.0);

  /// Плавное приближение планеты (100% → 110%), якорь — левый край.
  static const zoomScale = 1.1;
  static const zoomDuration = Duration(seconds: 10);

  static bool isPreloaded = false;

  static Future<void> preload() async {
    if (isPreloaded) return;
    await rootBundle.load(path);
    isPreloaded = true;
  }
}
