const config = require('../config');

const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);

function resolveMimeType(buffer, mimeType, fileName) {
  if (mimeType && ALLOWED_MIME.has(mimeType)) {
    return mimeType;
  }

  const lower = String(fileName || '').toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';

  if (buffer && buffer.length >= 2) {
    if (buffer[0] === 0x89 && buffer[1] === 0x50) return 'image/png';
    if (buffer[0] === 0xff && buffer[1] === 0xd8) return 'image/jpeg';
    if (
      buffer.length >= 12 &&
      buffer.toString('ascii', 0, 4) === 'RIFF' &&
      buffer.toString('ascii', 8, 12) === 'WEBP'
    ) {
      return 'image/webp';
    }
  }

  return mimeType || '';
}

function moderatePhoto(buffer, mimeType, fileName = '') {
  const resolved = resolveMimeType(buffer, mimeType, fileName);

  if (!ALLOWED_MIME.has(resolved)) {
    return { ok: false, error: 'Допустимы только JPG, PNG или WEBP' };
  }

  if (!buffer || buffer.length === 0) {
    return { ok: false, error: 'Пустой файл' };
  }

  if (buffer.length > config.photoMaxBytes) {
    return {
      ok: false,
      error: `Файл слишком большой (макс. ${Math.round(config.photoMaxBytes / 1024 / 1024)} МБ)`,
    };
  }

  if (config.photoMockModeration || !config.visionApiKey) {
    return { ok: true, mock: true };
  }

  // Боевой Yandex Vision подключим при наличии ключа (пока тестовый пропуск)
  return { ok: true, mock: true };
}

module.exports = { moderatePhoto, resolveMimeType };
