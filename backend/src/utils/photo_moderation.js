const config = require('../config');
const { validateListingText } = require('./stop_words');
const { validateProhibitedGoods } = require('./prohibited_goods');
const { analyzeImageForModeration } = require('../services/vision_service');

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

function validateBasicPhoto(buffer, mimeType, fileName = '') {
  const resolved = resolveMimeType(buffer, mimeType, fileName);

  if (!ALLOWED_MIME.has(resolved)) {
    const lowerMime = String(mimeType || '').toLowerCase();
    if (lowerMime.includes('svg') || lowerMime.startsWith('text/') || lowerMime.startsWith('application/')) {
      return { ok: false, error: 'Допустимы только JPG, PNG или WEBP' };
    }
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

  return { ok: true, mimeType: resolved };
}

function validatePhotoText(extractedText) {
  if (!extractedText) {
    return { ok: true };
  }

  const stopCheck = validateListingText(extractedText, '');
  if (!stopCheck.ok) {
    return {
      ok: false,
      error:
        'На фото обнаружен запрещённый текст (продажа, ссылки или контакты). ' +
        'Загрузите другое изображение без таких надписей.',
      code: 'PHOTO_TEXT_STOP_WORD',
    };
  }

  const goodsCheck = validateProhibitedGoods(extractedText, '', '', '');
  if (!goodsCheck.ok) {
    return {
      ok: false,
      error:
        'На фото обнаружены признаки запрещённого или лицензируемого товара. ' +
        'Загрузите другое изображение.',
      code: 'PHOTO_TEXT_PROHIBITED_GOODS',
      kind: goodsCheck.kind,
    };
  }

  return { ok: true };
}

async function moderatePhoto(buffer, mimeType, fileName = '') {
  const basic = validateBasicPhoto(buffer, mimeType, fileName);
  if (!basic.ok) {
    return basic;
  }

  const useMock = config.photoMockModeration || !config.visionApiKey;
  if (useMock) {
    if (!config.photoMockModeration && !config.visionApiKey) {
      return {
        ok: false,
        error:
          'Проверка фото не настроена на сервере. Обратитесь в поддержку «Даром».',
        code: 'VISION_NOT_CONFIGURED',
      };
    }
    return { ok: true, mock: true, mimeType: basic.mimeType };
  }

  try {
    const vision = await analyzeImageForModeration({
      buffer,
      mimeType: basic.mimeType,
      apiKey: config.visionApiKey,
      folderId: config.visionFolderId,
      threshold: config.visionModerationThreshold,
    });

    if (!vision.moderation.ok) {
      return {
        ok: false,
        error:
          `Фото не прошло модерацию: ${vision.moderation.reason}. ` +
          'Загрузите обычное фото вещи без запрещённого содержания.',
        code: 'PHOTO_MODERATION',
        label: vision.moderation.label,
        score: vision.moderation.score,
      };
    }

    const textCheck = validatePhotoText(vision.extractedText);
    if (!textCheck.ok) {
      return textCheck;
    }

    return {
      ok: true,
      mock: false,
      mimeType: basic.mimeType,
      visionScores: vision.scores,
    };
  } catch (error) {
    const message =
      error?.name === 'AbortError'
        ? 'Сервис проверки фото не ответил вовремя. Попробуйте ещё раз.'
        : 'Сервис проверки фото временно недоступен. Попробуйте позже.';

    return {
      ok: false,
      error: message,
      code: 'VISION_ERROR',
      details: error.message,
    };
  }
}

module.exports = { moderatePhoto, resolveMimeType, validateBasicPhoto };
