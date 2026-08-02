import 'package:http/http.dart' as http;

/// Слишком много запросов (HTTP 429).
class RateLimitException implements Exception {
  RateLimitException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _rateLimitMessage = 'Слишком много запросов. Подождите минуту.';

Future<http.Response> daromGet(
  http.Client client,
  Uri uri, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 15),
  int maxRetries = 2,
}) {
  return _requestWithRetry(
    () => client.get(uri, headers: headers).timeout(timeout),
    maxRetries: maxRetries,
  );
}

Future<http.Response> daromPost(
  http.Client client,
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Duration timeout = const Duration(seconds: 15),
  int maxRetries = 2,
}) {
  return _requestWithRetry(
    () => client.post(uri, headers: headers, body: body).timeout(timeout),
    maxRetries: maxRetries,
  );
}

Future<http.Response> _requestWithRetry(
  Future<http.Response> Function() send, {
  required int maxRetries,
}) async {
  for (var attempt = 0; attempt <= maxRetries; attempt++) {
    final response = await send();
    if (response.statusCode != 429 || attempt == maxRetries) {
      return response;
    }
    await Future<void>.delayed(Duration(seconds: 2 + attempt * 2));
  }
  throw StateError('_requestWithRetry: unreachable');
}

String rateLimitErrorMessage(http.Response response) {
  if (response.statusCode != 429) return '';
  try {
    final decoded = response.body;
    if (decoded.contains('Подождите')) return _rateLimitMessage;
  } catch (_) {}
  return _rateLimitMessage;
}
