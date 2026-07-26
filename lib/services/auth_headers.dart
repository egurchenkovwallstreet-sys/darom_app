import 'session_service.dart';

/// Заголовки с Bearer-токеном после входа по PIN (этап I-A).
/// На боевом Web — сессия в HttpOnly-cookie, Bearer не нужен.
Future<Map<String, String>> authHeaders() async {
  final token = await SessionService.getToken();
  final headers = <String, String>{};
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}

Future<Map<String, String>> jsonAuthHeaders() async {
  final headers = await authHeaders();
  headers['Content-Type'] = 'application/json';
  return headers;
}

/// Токен сессии Flash Call / Mobile ID — только в заголовке, не в URL.
Map<String, String> withVerifySessionToken(
  Map<String, String> headers,
  String sessionToken,
) {
  return {
    ...headers,
    'X-Verify-Session-Token': sessionToken,
  };
}

Future<Map<String, String>> verifySessionHeaders(String sessionToken) async {
  return withVerifySessionToken(await authHeaders(), sessionToken);
}

Future<Map<String, String>> verifySessionJsonHeaders(String sessionToken) async {
  return withVerifySessionToken(await jsonAuthHeaders(), sessionToken);
}

Map<String, String> verifySessionJsonHeadersPublic(String sessionToken) {
  return withVerifySessionToken(
    const {'Content-Type': 'application/json'},
    sessionToken,
  );
}

Map<String, String> verifySessionHeadersPublic(String sessionToken) {
  return {'X-Verify-Session-Token': sessionToken};
}
