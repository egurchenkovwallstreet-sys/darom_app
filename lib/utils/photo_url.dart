import '../services/api_config.dart';

String resolvePhotoUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  final match = RegExp(r'/api/photos/listings/([^/?#]+)').firstMatch(url);
  if (match != null) {
    return '${ApiConfig.baseUrl}/api/photos/listings/${match.group(1)}';
  }

  return url;
}

String resolveAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  final match = RegExp(r'/api/photos/avatars/([^/?#]+)').firstMatch(url);
  if (match != null) {
    return '${ApiConfig.baseUrl}/api/photos/avatars/${match.group(1)}';
  }

  final uploadsMatch = RegExp(r'/uploads/avatars/([^/?#]+)').firstMatch(url);
  if (uploadsMatch != null) {
    return '${ApiConfig.baseUrl}/api/photos/avatars/${uploadsMatch.group(1)}';
  }

  return url;
}
