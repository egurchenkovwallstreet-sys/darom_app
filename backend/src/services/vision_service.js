const VISION_URL = 'https://vision.api.cloud.yandex.net/vision/v1/batchAnalyze';
const VISION_TIMEOUT_MS = 45000;
const VISION_MAX_BYTES = 1024 * 1024;

const REJECT_LABELS = {
  adult: 'взрослый или неприемлемый контент',
  gruesome: 'насилие или шокирующие изображения',
};

function mimeToVisionFormat(mimeType) {
  switch (mimeType) {
    case 'image/png':
      return 'PNG';
    case 'image/webp':
      return 'WEBP';
    default:
      return 'JPEG';
  }
}

function buildAnalyzeBody(buffer, mimeType, folderId) {
  const body = {
    analyze_specs: [
      {
        content: buffer.toString('base64'),
        mime_type: mimeToVisionFormat(mimeType),
        features: [
          {
            type: 'CLASSIFICATION',
            classificationConfig: {
              model: 'moderation',
            },
          },
          {
            type: 'TEXT_DETECTION',
            textDetectionConfig: {
              languageCodes: ['ru', 'en'],
            },
          },
        ],
      },
    ],
  };

  if (folderId) {
    body.folderId = folderId;
  }

  return body;
}

function parseProbability(value) {
  const num = Number(value);
  return Number.isFinite(num) ? num : 0;
}

function collectModerationScores(response) {
  const scores = {};
  const results = response?.results?.[0]?.results || [];

  for (const item of results) {
    const properties = item?.classification?.properties || [];
    for (const property of properties) {
      if (!property?.name) continue;
      const current = scores[property.name] || 0;
      scores[property.name] = Math.max(current, parseProbability(property.probability));
    }
  }

  return scores;
}

function extractTextFromVision(response) {
  const chunks = [];
  const results = response?.results?.[0]?.results || [];

  for (const item of results) {
    const pages = item?.textDetection?.pages || item?.text_detection?.pages || [];
    for (const page of pages) {
      const blocks = page?.blocks || [];
      for (const block of blocks) {
        const lines = block?.lines || [];
        for (const line of lines) {
          const words = line?.words || [];
          const lineText = words
            .map((word) => word?.text || '')
            .join(' ')
            .trim();
          if (lineText) chunks.push(lineText);
        }
      }
    }
  }

  return chunks.join(' ').trim();
}

function evaluateModerationScores(scores, threshold) {
  for (const [label, reason] of Object.entries(REJECT_LABELS)) {
    const score = scores[label] || 0;
    if (score >= threshold) {
      return {
        ok: false,
        label,
        score,
        reason,
      };
    }
  }

  return { ok: true, scores };
}

async function prepareVisionBuffer(buffer) {
  if (buffer.length <= VISION_MAX_BYTES) {
    return buffer;
  }

  let sharp;
  try {
    sharp = require('sharp');
  } catch {
    throw new Error(
      'Фото больше 1 МБ, а модуль сжатия не установлен на сервере (npm install sharp)',
    );
  }

  let quality = 85;
  let output = await sharp(buffer).rotate().jpeg({ quality, mozjpeg: true }).toBuffer();

  while (output.length > VISION_MAX_BYTES && quality > 45) {
    quality -= 10;
    output = await sharp(buffer).rotate().jpeg({ quality, mozjpeg: true }).toBuffer();
  }

  if (output.length > VISION_MAX_BYTES) {
    output = await sharp(buffer)
      .rotate()
      .resize(1600, 1600, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 70, mozjpeg: true })
      .toBuffer();
  }

  if (output.length > VISION_MAX_BYTES) {
    throw new Error('Не удалось подготовить фото для проверки (лимит Yandex Vision — 1 МБ)');
  }

  return output;
}

async function callVisionApi({ buffer, mimeType, apiKey, folderId }) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), VISION_TIMEOUT_MS);

  try {
    const response = await fetch(VISION_URL, {
      method: 'POST',
      headers: {
        Authorization: `Api-Key ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(buildAnalyzeBody(buffer, mimeType, folderId)),
      signal: controller.signal,
    });

    const raw = await response.text();
    let data = null;
    if (raw) {
      try {
        data = JSON.parse(raw);
      } catch {
        data = null;
      }
    }

    if (!response.ok) {
      const message =
        data?.message ||
        data?.error?.message ||
        raw?.slice(0, 200) ||
        `HTTP ${response.status}`;
      throw new Error(message);
    }

    return data || {};
  } finally {
    clearTimeout(timeout);
  }
}

async function analyzeImageForModeration({
  buffer,
  mimeType,
  apiKey,
  folderId,
  threshold,
}) {
  const visionBuffer = await prepareVisionBuffer(buffer);
  const response = await callVisionApi({
    buffer: visionBuffer,
    mimeType: 'image/jpeg',
    apiKey,
    folderId,
  });
  const scores = collectModerationScores(response);
  const moderation = evaluateModerationScores(scores, threshold);
  const extractedText = extractTextFromVision(response);

  return {
    moderation,
    scores,
    extractedText,
  };
}

module.exports = {
  analyzeImageForModeration,
  collectModerationScores,
  evaluateModerationScores,
  extractTextFromVision,
};
