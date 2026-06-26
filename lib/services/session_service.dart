import '../models/user.dart';
import 'session_storage.dart';

/// Сохраняет вход пользователя между запусками приложения.
class SessionService {
  SessionService._();

  static const _keyUserId = 'session_user_id';
  static const _keyPhone = 'session_phone';
  static const _keyName = 'session_name';
  static const _keyToken = 'session_token';

  static Future<String?> getToken() => readString(_keyToken);

  static Future<void> saveToken(String token) async {
    await saveString(_keyToken, token);
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
    await saveToken(sessionToken);
  }

  static Future<SessionData?> load() async {
    final phone = await readString(_keyPhone);
    final name = await readString(_keyName);
    final token = await readString(_keyToken);

    if (phone == null || name == null || token == null || token.isEmpty) {
      if (phone != null && (token == null || token.isEmpty)) {
        await clear();
      }
      return null;
    }

    return SessionData(
      userId: await readString(_keyUserId),
      phoneNumber: phone,
      name: name,
      sessionToken: token,
    );
  }

  static Future<void> clear() async {
    await removeKey(_keyUserId);
    await removeKey(_keyPhone);
    await removeKey(_keyName);
    await removeKey(_keyToken);
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
}

class SessionData {
  final String? userId;
  final String phoneNumber;
  final String name;
  final String sessionToken;

  const SessionData({
    required this.userId,
    required this.phoneNumber,
    required this.name,
    required this.sessionToken,
  });
}
