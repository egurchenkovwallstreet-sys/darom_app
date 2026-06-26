import 'session_service.dart';

/// Заголовки с Bearer-токеном после входа по PIN (этап I-A).
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
