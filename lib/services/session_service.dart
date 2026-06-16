import '../models/user.dart';
import 'session_storage.dart';

/// Сохраняет вход пользователя между запусками приложения.
class SessionService {
  SessionService._();

  static const _keyUserId = 'session_user_id';
  static const _keyPhone = 'session_phone';
  static const _keyName = 'session_name';

  static Future<void> save(User user) async {
    await saveString(_keyUserId, user.id);
    await saveString(_keyPhone, user.phoneNumber);
    await saveString(_keyName, user.name);
  }

  static Future<SessionData?> load() async {
    final phone = await readString(_keyPhone);
    final name = await readString(_keyName);

    if (phone == null || name == null) {
      return null;
    }

    return SessionData(
      userId: await readString(_keyUserId),
      phoneNumber: phone,
      name: name,
    );
  }

  static Future<void> clear() async {
    await removeKey(_keyUserId);
    await removeKey(_keyPhone);
    await removeKey(_keyName);
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

  const SessionData({
    required this.userId,
    required this.phoneNumber,
    required this.name,
  });
}
