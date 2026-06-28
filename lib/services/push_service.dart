import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'push_service_platform.dart'
    if (dart.library.html) 'push_service_web.dart'
    if (dart.library.io) 'push_service_io.dart';
import 'users_api.dart';

enum PushRegisterResult {
  success,
  notConfigured,
  denied,
  failed,
  alreadyRegistered,
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();
  static final http.Client _client = http.Client();

  static bool _firebaseInitialized = false;
  static bool _listenersAttached = false;
  static String? _registeredPhone;
  static String? lastErrorMessage;

  /// Только после нажатия «Включить» — иначе браузер не показывает запрос.
  Future<PushRegisterResult> requestPermissionAndRegister({required String phone}) async {
    lastErrorMessage = null;
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      lastErrorMessage = 'empty_phone';
      return PushRegisterResult.failed;
    }

    try {
      final config = await _ensureFirebaseReady();
      if (config == null) return PushRegisterResult.notConfigured;

      if (_registeredPhone == normalizedPhone) {
        return PushRegisterResult.alreadyRegistered;
      }

      if (kIsWeb) {
        await ensureMessagingServiceWorker();
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return _registerTokenIfAllowed(
        phone: normalizedPhone,
        messaging: messaging,
        config: config,
        settings: settings,
      );
    } catch (error) {
      lastErrorMessage = '$error';
      if (kDebugMode) debugPrint('Push register failed: $error');
      return PushRegisterResult.failed;
    }
  }

  /// Без запроса разрешения — если пользователь уже разрешил раньше.
  Future<PushRegisterResult> registerIfAlreadyAuthorized({required String phone}) async {
    lastErrorMessage = null;
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      lastErrorMessage = 'empty_phone';
      return PushRegisterResult.failed;
    }

    try {
      final config = await _ensureFirebaseReady();
      if (config == null) return PushRegisterResult.notConfigured;

      if (_registeredPhone == normalizedPhone) {
        return PushRegisterResult.alreadyRegistered;
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (!_isAllowed(settings)) return PushRegisterResult.denied;

      if (kIsWeb) {
        await ensureMessagingServiceWorker();
      }

      return _registerTokenIfAllowed(
        phone: normalizedPhone,
        messaging: messaging,
        config: config,
        settings: settings,
      );
    } catch (error) {
      lastErrorMessage = '$error';
      if (kDebugMode) debugPrint('Push silent register failed: $error');
      return PushRegisterResult.failed;
    }
  }

  Future<AuthorizationStatus?> getPermissionStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (_) {
      return null;
    }
  }

  Future<PushRegisterResult> _registerTokenIfAllowed({
    required String phone,
    required FirebaseMessaging messaging,
    required _FirebaseWebConfig config,
    required NotificationSettings settings,
  }) async {
    if (!_isAllowed(settings)) {
      return PushRegisterResult.denied;
    }

    final token = await _fetchDeviceToken(messaging: messaging, config: config);
    if (token == null || token.isEmpty) {
      lastErrorMessage ??= 'empty_fcm_token';
      return PushRegisterResult.failed;
    }

    try {
      await UsersApi().registerPushToken(
        phone: phone,
        token: token,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );
    } catch (error) {
      lastErrorMessage = error is UsersApiException ? error.message : '$error';
      return PushRegisterResult.failed;
    }

    _registeredPhone = phone;
    _attachListeners();

    return PushRegisterResult.success;
  }

  Future<String?> _fetchDeviceToken({
    required FirebaseMessaging messaging,
    required _FirebaseWebConfig config,
  }) async {
    if (kIsWeb) {
      try {
        return await getWebFcmToken(config.vapidKey);
      } catch (error) {
        lastErrorMessage = _humanizeWebTokenError('$error');
        if (kDebugMode) debugPrint('Push web token failed: $error');
        return null;
      }
    }

    return messaging.getToken();
  }

  String _humanizeWebTokenError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('service_worker_unsupported')) {
      return 'Браузер не поддерживает push-уведомления';
    }
    if (lower.contains('push service not available')) {
      return 'Push-сервис браузера недоступен (попробуйте Chrome или добавьте сайт на экран «Домой» на iPhone)';
    }
    if (lower.contains('vapid')) {
      return 'Ошибка VAPID-ключа Firebase на сервере';
    }
    if (lower.contains('firebase_not_configured')) {
      return 'Firebase не настроен на сервере';
    }
    if (lower.contains('unsupported-browser') || lower.contains('unsupported_browser')) {
      return 'Этот браузер не поддерживает push. На iPhone добавьте «Даром» на экран «Домой»';
    }
    if (lower.contains('not a subtype') || lower.contains('typeerror')) {
      return 'Ошибка связи с Firebase. Обновите страницу и попробуйте снова';
    }
    return raw;
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    // На Web токен и фоновые push идут через push_helper.js + firebase-messaging-sw.js.
    if (kIsWeb) return;

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (_registeredPhone == null) return;
      await UsersApi().registerPushToken(
        phone: _registeredPhone!,
        token: newToken,
        platform: defaultTargetPlatform.name,
      );
    });

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint('Push foreground: ${message.notification?.title}');
      }
    });
  }

  bool _isAllowed(NotificationSettings settings) {
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<_FirebaseWebConfig?> _ensureFirebaseReady() async {
    final config = await _loadFirebaseConfig();
    if (config == null) {
      lastErrorMessage = 'firebase_config_missing';
      if (kDebugMode) {
        debugPrint('Push: Firebase не настроен на сервере — пропуск');
      }
      return null;
    }

    // На Web токен берём через push_helper.js (compat + serviceWorkerRegistration).
    // Modular Firebase.initializeApp здесь не нужен и может конфликтовать с compat.
    if (kIsWeb) {
      return config;
    }

    if (!_firebaseInitialized) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config.apiKey,
          appId: config.appId,
          messagingSenderId: config.messagingSenderId,
          projectId: config.projectId,
          authDomain: '${config.projectId}.firebaseapp.com',
          storageBucket: '${config.projectId}.appspot.com',
        ),
      );
      _firebaseInitialized = true;
    }

    return config;
  }

  Future<_FirebaseWebConfig?> _loadFirebaseConfig() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/config/firebase');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['configured'] != true) return null;

    return _FirebaseWebConfig(
      projectId: body['project_id'] as String? ?? '',
      apiKey: body['api_key'] as String? ?? '',
      appId: body['app_id'] as String? ?? '',
      messagingSenderId: body['messaging_sender_id'] as String? ?? '',
      vapidKey: body['vapid_key'] as String? ?? '',
    );
  }
}

class _FirebaseWebConfig {
  const _FirebaseWebConfig({
    required this.projectId,
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.vapidKey,
  });

  final String projectId;
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String vapidKey;
}
