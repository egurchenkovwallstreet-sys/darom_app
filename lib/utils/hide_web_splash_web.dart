import 'dart:js_interop';

import 'package:flutter/scheduler.dart';

@JS('daromHideSplash')
external void _daromHideSplash();

void hideWebSplashAfterFirstFrame() {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    try {
      _daromHideSplash();
    } catch (_) {}
  });
}
