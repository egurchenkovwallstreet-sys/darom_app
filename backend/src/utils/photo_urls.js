const config = require('../config');

function buildPhotoUrl(fileName) {
  return `${config.publicBaseUrl}/api/photos/listings/${fileName}`;
}

function buildAvatarUrl(fileName) {
  return `${config.publicBaseUrl}/api/photos/avatars/${fileName}`;
}

function normalizeAvatarUrl(url) {
  if (!url) return url;
  if (url.includes('/api/photos/avatars/')) return url;

  const match = String(url).match(/\/avatars\/([^/?#]+)$/i);
  if (match) {
    return buildAvatarUrl(match[1]);
  }

  return url;
}

function normalizePhotoUrl(url) {
  if (!url) return url;
  if (url.includes('/api/photos/listings/')) return url;

  const listingsMatch = String(url).match(/\/listings\/([^/?#]+)$/i);
  if (listingsMatch) {
    return buildPhotoUrl(listingsMatch[1]);
  }

  const uploadsMatch = String(url).match(/\/uploads\/([^/?#]+)$/i);
  if (uploadsMatch) {
    return buildPhotoUrl(uploadsMatch[1]);
  }

  return url;
}

function normalizePhotoUrls(urls) {
  if (!Array.isArray(urls)) return [];
  return urls.map((url) => normalizePhotoUrl(String(url)));
}

module.exports = { buildPhotoUrl, buildAvatarUrl, normalizePhotoUrl, normalizePhotoUrls, normalizeAvatarUrl };
