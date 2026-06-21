require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const path = require('path');

const port = Number(process.env.PORT) || 3000;
const publicBaseUrl = process.env.PUBLIC_BASE_URL || `http://localhost:${port}`;

const config = {
  port,
  databaseUrl: process.env.DATABASE_URL,
  smsProvider: (process.env.SMS_PROVIDER || 'smsaero').toLowerCase(),
  smsRuApiId: process.env.SMS_RU_API_ID || '',
  smsAeroEmail: process.env.SMS_AERO_EMAIL || '',
  smsAeroApiKey: process.env.SMS_AERO_API_KEY || '',
  smsAeroSign: process.env.SMS_AERO_SIGN || 'SMS Aero',
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
  deploySecret: process.env.DEPLOY_SECRET || '',
  webRoot: process.env.WEB_ROOT || '/var/www/darom',
  adminSecret: process.env.ADMIN_SECRET || '',
  adminPhone: process.env.ADMIN_PHONE || '79138931428',
  adminEmail: process.env.ADMIN_EMAIL || 'e.gurchenkov@yandex.ru',
  adminEmailMock: process.env.ADMIN_EMAIL_MOCK !== 'false',
  smtp: {
    host: process.env.SMTP_HOST || '',
    port: Number(process.env.SMTP_PORT || 465),
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
  },
  robokassa: {
    merchantLogin: process.env.ROBOKASSA_MERCHANT_LOGIN || '',
    password1: process.env.ROBOKASSA_PASSWORD1 || '',
    password2: process.env.ROBOKASSA_PASSWORD2 || '',
    testPassword1: process.env.ROBOKASSA_TEST_PASSWORD1 || '',
    testPassword2: process.env.ROBOKASSA_TEST_PASSWORD2 || '',
    testMode: process.env.ROBOKASSA_TEST_MODE === 'true',
  },
  paymentMock: process.env.PAYMENT_MOCK !== 'false',
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

if (config.smsMock) {
  console.log('SMS: тестовый режим (SMS_MOCK=true или не задано SMS_MOCK=false)');
} else if (config.smsAeroEmail && config.smsAeroApiKey) {
  console.log(`✓ SMS Aero: боевой режим, ${config.smsAeroEmail}, sign="${config.smsAeroSign}"`);
} else if (config.smsRuApiId) {
  console.log('✓ SMS.ru: боевой режим');
} else {
  console.warn('⚠ SMS: SMS_MOCK=false, но SMS_AERO_EMAIL / SMS_AERO_API_KEY пустые — коды будут тестовыми');
}

module.exports = config;
