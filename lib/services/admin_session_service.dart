import 'session_storage.dart';

class AdminSessionService {
  AdminSessionService._();

  static const _keyToken = 'admin_session_token';
  static const _keyRole = 'admin_session_role';

  static Future<void> save({required String token, required String role}) async {
    await saveString(_keyToken, token);
    await saveString(_keyRole, role);
  }

  static Future<AdminSessionData?> load() async {
    final token = await readString(_keyToken);
    if (token == null || token.isEmpty) return null;
    return AdminSessionData(
      token: token,
      role: await readString(_keyRole) ?? 'super_admin',
    );
  }

  static Future<void> clear() async {
    await removeKey(_keyToken);
    await removeKey(_keyRole);
  }
}

class AdminSessionData {
  const AdminSessionData({required this.token, required this.role});

  final String token;
  final String role;

  bool get isSuperAdmin => role == 'super_admin';
}
