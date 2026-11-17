import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';

/// Отложенная часть кода (`import ... deferred as x`), которую web-сборка
/// скачивает отдельным файлом. Запоминает, что часть уже загружена, чтобы
/// повторное открытие экрана не мигало индикатором.
class DeferredLibrary {
  DeferredLibrary(this._loader);

  final Future<void> Function() _loader;
  Future<void>? _future;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() {
    return _future ??= _loader().then(
      (_) => _loaded = true,
      onError: (Object error, StackTrace stack) {
        _future = null;
        return Future<void>.error(error, stack);
      },
    );
  }

  /// Докачивает части по одной, не мешая уже открытому экрану.
  static Future<void> preloadInOrder(Iterable<DeferredLibrary> libraries) async {
    for (final library in libraries) {
      if (library.isLoaded) continue;
      try {
        await library.load();
      } catch (_) {
        // Сеть мигнула — часть докачается при открытии экрана.
      }
    }
  }
}

/// Экран из [DeferredLibrary]: пока часть кода качается — индикатор,
/// при ошибке сети — кнопка повтора.
class DeferredScreen extends StatefulWidget {
  const DeferredScreen({
    super.key,
    required this.library,
    required this.builder,
  });

  final DeferredLibrary library;

  /// Вызывается только после загрузки — можно обращаться к классам
  /// отложенной библиотеки.
  final WidgetBuilder builder;

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (widget.library.isLoaded) return;
    widget.library.load().then((_) {
      if (mounted) setState(() => _error = null);
    }, onError: (Object error) {
      if (mounted) setState(() => _error = error);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.library.isLoaded) {
      return widget.builder(context);
    }
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: _error == null
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Не удалось загрузить раздел. Проверьте интернет.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _error = null);
                        _load();
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
