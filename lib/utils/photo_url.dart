import '../services/api_config.dart';

String resolvePhotoUrl(String? url, {int? maxPixelWidth}) {
  if (url == null || url.isEmpty) return '';

  final match = RegExp(r'/api/photos/listings/([^/?#]+)').firstMatch(url);
  if (match != null) {
    final file = match.group(1)!;
    final base = '${ApiConfig.baseUrl}/api/photos/listings/$file';
    if (maxPixelWidth != null && maxPixelWidth > 0 && maxPixelWidth < 1600) {
      return '$base?w=$maxPixelWidth';
    }
    return base;
  }

  if (url.startsWith('http://localhost') || url.startsWith('http://127.0.0.1')) {
    return '';
  }

  return url;
}

String resolveAvatarUrl(String? url, {int? maxPixelWidth}) {
  if (url == null || url.isEmpty) return '';

  final match = RegExp(r'/api/photos/avatars/([^/?#]+)').firstMatch(url);
  if (match != null) {
    final file = match.group(1)!;
    final base = '${ApiConfig.baseUrl}/api/photos/avatars/$file';
    if (maxPixelWidth != null && maxPixelWidth > 0 && maxPixelWidth < 1600) {
      return '$base?w=$maxPixelWidth';
    }
    return base;
  }

  final uploadsMatch = RegExp(r'/uploads/avatars/([^/?#]+)').firstMatch(url);
  if (uploadsMatch != null) {
    return '${ApiConfig.baseUrl}/api/photos/avatars/${uploadsMatch.group(1)}';
  }

  return url;
}
