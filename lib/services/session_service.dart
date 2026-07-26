import '../models/user.dart';
import 'api_config.dart';
import 'session_storage.dart';

/// Сохраняет вход пользователя между запусками приложения.
class SessionService {
  SessionService._();

  static const _keyUserId = 'session_user_id';
  static const _keyPhone = 'session_phone';
  static const _keyName = 'session_name';
  static const _keyToken = 'session_token';
  static const _keyCookieMode = 'session_cookie_v1';

  static Future<String?> getToken() async {
    if (ApiConfig.usesHttpOnlySessionCookie &&
        await readString(_keyCookieMode) == '1') {
      return null;
    }
    return readString(_keyToken);
  }

  static Future<void> saveToken(String token) async {
    await saveString(_keyToken, token);
    await removeKey(_keyCookieMode);
  }

  static Future<void> save(User user) async {
    await saveString(_keyUserId, user.id);
    await saveString(_keyPhone, user.phoneNumber);
    await saveString(_keyName, user.name);
  }

  static Future<void> saveLogin({
    required User user,
    required String sessionToken,
  }) async {
    await save(user);
    if (ApiConfig.usesHttpOnlySessionCookie) {
      await saveString(_keyCookieMode, '1');
      await removeKey(_keyToken);
    } else {
      await saveToken(sessionToken);
    }
  }

  static Future<SessionData?> load() async {
    final phone = await readString(_keyPhone);
    final name = await readString(_keyName);

    if (phone == null || name == null) {
      return null;
    }

    if (ApiConfig.usesHttpOnlySessionCookie &&
        await readString(_keyCookieMode) == '1') {
      return SessionData(
        userId: await readString(_keyUserId),
        phoneNumber: phone,
        name: name,
        sessionToken: '',
        usesCookie: true,
      );
    }

    final token = await readString(_keyToken);
    if (token == null || token.isEmpty) {
      await clear();
      return null;
    }

    return SessionData(
      userId: await readString(_keyUserId),
      phoneNumber: phone,
      name: name,
      sessionToken: token,
      usesCookie: false,
    );
  }

  static Future<void> clear() async {
    await removeKey(_keyUserId);
    await removeKey(_keyPhone);
    await removeKey(_keyName);
    await removeKey(_keyToken);
    await removeKey(_keyCookieMode);
  }

  /// Сбрасывает старый локальный вход без Bearer-токена (этап I-A).
  static Future<void> migrateToTokenSessionIfNeeded() async {
    const key = 'session_token_v1';
    if (await readString(key) == '1') return;
    await clear();
    await saveString(key, '1');
  }

  /// Один раз сбрасывает старый локальный вход после перехода на сервер Timeweb.
  static Future<void> migrateToRemoteServerIfNeeded() async {
    const key = 'session_migrated_to_remote_v1';
    if (await readString(key) == '1') return;
    await clear();
    await saveString(key, '1');
  }

  /// Переход на HttpOnly-cookie на боевом сайте (J-H).
  static Future<void> migrateToHttpOnlyCookieIfNeeded() async {
    if (!ApiConfig.usesHttpOnlySessionCookie) return;
    const key = 'session_cookie_migrated_v1';
    if (await readString(key) == '1') return;
    await removeKey(_keyToken);
    await saveString(key, '1');
  }
}

class SessionData {
  final String? userId;
  final String phoneNumber;
  final String name;
  final String sessionToken;
  final bool usesCookie;

  const SessionData({
    required this.userId,
    required this.phoneNumber,
    required this.name,
    required this.sessionToken,
    this.usesCookie = false,
  });
}
