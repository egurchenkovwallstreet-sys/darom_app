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
        return _registerWebPush(phone: normalizedPhone, config: config);
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

      if (kIsWeb) {
        final status = await getPermissionStatus();
        if (status != AuthorizationStatus.authorized &&
            status != AuthorizationStatus.provisional) {
          return PushRegisterResult.denied;
        }
        await ensureMessagingServiceWorker();
        return _registerWebPush(phone: normalizedPhone, config: config, skipPermissionRequest: true);
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (!_isAllowed(settings)) return PushRegisterResult.denied;

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
    if (kIsWeb) {
      return getWebPermissionStatus();
    }

    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (_) {
      return null;
    }
  }

  Future<PushRegisterResult> _registerWebPush({
    required String phone,
    required _FirebaseWebConfig config,
    bool skipPermissionRequest = false,
  }) async {
    if (skipPermissionRequest) {
      final status = await getPermissionStatus();
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        return PushRegisterResult.denied;
      }
    }

    final result = await registerWebPush(config.vapidKey);
    if (!result.ok) {
      if (result.error == 'permission_denied') {
        return PushRegisterResult.denied;
      }
      lastErrorMessage = _humanizeWebTokenError(result.error ?? 'fcm_failed');
      return PushRegisterResult.failed;
    }

    return _saveToken(phone: phone, token: result.token!);
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

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      lastErrorMessage = 'empty_fcm_token';
      return PushRegisterResult.failed;
    }

    return _saveToken(phone: phone, token: token);
  }

  Future<PushRegisterResult> _saveToken({
    required String phone,
    required String token,
  }) async {
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

  String _humanizeWebTokenError(String? raw) {
    final text = raw ?? 'fcm_failed';
    final lower = text.toLowerCase();
    if (lower.contains('service_worker_unsupported') || lower.contains('notifications_unsupported')) {
      return 'Браузер не поддерживает push-уведомления';
    }
    if (lower.contains('push service not available')) {
      return 'Push-сервис браузера недоступен. На iPhone добавьте «Даром» на экран «Домой» (Safari → Поделиться)';
    }
    if (lower.contains('unsupported-browser') || lower.contains('unsupported_browser')) {
      return 'Этот браузер не поддерживает push. На iPhone — только через иконку «На экран Домой»';
    }
    if (lower.contains('vapid')) {
      return 'Ошибка VAPID-ключа Firebase на сервере';
    }
    if (lower.contains('firebase_not_configured')) {
      return 'Firebase не настроен на сервере';
    }
    if (lower.contains('empty_fcm_token')) {
      return 'Firebase не выдал токен. На iPhone добавьте сайт на экран «Домой»';
    }
    return text;
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
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
