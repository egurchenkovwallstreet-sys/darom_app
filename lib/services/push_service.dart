import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'users_api.dart';

class PushService {
  PushService._();

  static final PushService instance = PushService._();
  static final http.Client _client = http.Client();

  static bool _initialized = false;
  static String? _registeredPhone;

  Future<void> registerForUser({required String phone}) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) return;
    if (_registeredPhone == normalizedPhone && _initialized) return;

    try {
      final config = await _loadFirebaseConfig();
      if (config == null) {
        if (kDebugMode) {
          debugPrint('Push: Firebase не настроен на сервере — пропуск');
        }
        return;
      }

      if (!_initialized) {
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
        _initialized = true;
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final allowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) {
        if (kDebugMode) debugPrint('Push: пользователь не разрешил уведомления');
        return;
      }

      final token = await messaging.getToken(
        vapidKey: kIsWeb ? config.vapidKey : null,
      );
      if (token == null || token.isEmpty) return;

      await UsersApi().registerPushToken(
        phone: normalizedPhone,
        token: token,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );

      _registeredPhone = normalizedPhone;

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (_registeredPhone == null) return;
        await UsersApi().registerPushToken(
          phone: _registeredPhone!,
          token: newToken,
          platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        );
      });

      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) {
          debugPrint('Push foreground: ${message.notification?.title}');
        }
      });
    } catch (error) {
      if (kDebugMode) debugPrint('Push register failed: $error');
    }
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
