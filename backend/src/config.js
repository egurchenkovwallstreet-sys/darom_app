require('dotenv').config();
const path = require('path');

const port = Number(process.env.PORT) || 3000;
const publicBaseUrl = process.env.PUBLIC_BASE_URL || `http://localhost:${port}`;

const config = {
  port,
  databaseUrl: process.env.DATABASE_URL,
  smsRuApiId: process.env.SMS_RU_API_ID || '',
  smsMock: process.env.SMS_MOCK !== 'false',
  publicBaseUrl,
  photoStorage:
    process.env.PHOTO_STORAGE ||
    (process.env.YC_S3_BUCKET && process.env.YC_S3_ACCESS_KEY ? 's3' : 'local'),
  uploadDir: path.join(__dirname, '..', process.env.UPLOAD_DIR || 'uploads'),
  photoMaxBytes: Number(process.env.PHOTO_MAX_MB || 5) * 1024 * 1024,
  photoMaxCount: Number(process.env.PHOTO_MAX_COUNT || 5),
  photoMockModeration: process.env.PHOTO_MOCK_MODERATION !== 'false',
  visionApiKey: process.env.YC_VISION_API_KEY || '',
  s3: {
    bucket: process.env.YC_S3_BUCKET || '',
    accessKey: process.env.YC_S3_ACCESS_KEY || '',
    secretKey: process.env.YC_S3_SECRET_KEY || '',
    endpoint: process.env.YC_S3_ENDPOINT || 'https://storage.yandexcloud.net',
    region: process.env.YC_S3_REGION || 'ru-central1',
    publicBaseUrl: process.env.YC_S3_PUBLIC_BASE_URL || '',
  },
};

if (!config.databaseUrl) {
  console.error('Ошибка: задай DATABASE_URL в файле backend/.env');
  process.exit(1);
}

if (config.photoStorage === 's3') {
  const missing = [];
  if (!config.s3.bucket) missing.push('YC_S3_BUCKET');
  if (!config.s3.accessKey) missing.push('YC_S3_ACCESS_KEY');
  if (!config.s3.secretKey) missing.push('YC_S3_SECRET_KEY');
  if (missing.length) {
    console.warn(`⚠ Фото: режим s3, но не заполнены: ${missing.join(', ')}`);
    console.warn('  Загрузка фото не будет работать, пока не добавите ключи в backend/.env');
  } else {
    const publicUrl =
      config.s3.publicBaseUrl || `${config.s3.endpoint}/${config.s3.bucket}`;
    console.log(`✓ Yandex Object Storage: бакет «${config.s3.bucket}», URL: ${publicUrl}`);
  }
}

module.exports = config;
