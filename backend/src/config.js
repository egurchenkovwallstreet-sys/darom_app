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
  smsAeroMobileIdSign: process.env.SMS_AERO_MOBILE_ID_SIGN || '',
  smsAuthMode: (process.env.SMS_AUTH_MODE || 'mobile_id').toLowerCase(),
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
  visionFolderId: process.env.YC_FOLDER_ID || '',
  visionModerationThreshold: Number(process.env.YC_VISION_MODERATION_THRESHOLD || 0.6),
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
  adminPhone: process.env.ADMIN_PHONE || '79138931428',
  adminEmail: process.env.ADMIN_EMAIL || 'e.gurchenkov@yandex.ru',
  adminEmailMock: process.env.ADMIN_EMAIL_MOCK !== 'false',
  adminEmailSmsFallback: process.env.ADMIN_EMAIL_SMS_FALLBACK !== 'false',
  pushMock: process.env.PUSH_MOCK !== 'false',
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    webApiKey: process.env.FIREBASE_WEB_API_KEY || '',
    webAppId: process.env.FIREBASE_WEB_APP_ID || '',
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || '',
    webVapidKey: process.env.FIREBASE_WEB_VAPID_KEY || '',
  },
  smtp: {
    host: process.env.SMTP_HOST || '',
    port: Number(process.env.SMTP_PORT || 465),
    secure: process.env.SMTP_SECURE !== 'false',
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
    from:
      process.env.SMTP_FROM ||
      process.env.SMTP_USER ||
      process.env.ADMIN_EMAIL ||
      'noreply@darom-app.online',
  },
  robokassa: {
    merchantLogin: (process.env.ROBOKASSA_MERCHANT_LOGIN || '').trim(),
    password1: process.env.ROBOKASSA_PASSWORD1 || '',
    password2: process.env.ROBOKASSA_PASSWORD2 || '',
    testPassword1: process.env.ROBOKASSA_TEST_PASSWORD1 || '',
    testPassword2: process.env.ROBOKASSA_TEST_PASSWORD2 || '',
    testMode: (process.env.ROBOKASSA_TEST_MODE || '').trim().toLowerCase() === 'true',
    /** Чек 54-ФЗ (Receipt) — обязателен для облачной кассы Robokassa. */
    fiscalReceipt: process.env.ROBOKASSA_FISCAL !== 'false',
    receiptTax: (process.env.ROBOKASSA_RECEIPT_TAX || 'none').trim(),
    sno: (process.env.ROBOKASSA_SNO || '').trim(),
  },
  paymentMock: process.env.PAYMENT_MOCK !== 'false',
  mobileIdWebhookSecret: process.env.MOBILE_ID_WEBHOOK_SECRET || '',
  corsOrigins: (process.env.CORS_ORIGINS || 'https://darom-app.online,http://localhost:8080,http://127.0.0.1:8080')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean),
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
  if (config.smsAeroMobileIdSign && config.smsAuthMode !== 'sms') {
    console.log(`✓ SMS Aero Mobile ID: ${config.smsAeroMobileIdSign}, webhook ${config.publicBaseUrl}/api/auth/mobile-id/webhook`);
    if (!config.mobileIdWebhookSecret) {
      console.warn('⚠ Mobile ID webhook: задайте MOBILE_ID_WEBHOOK_SECRET в .env (иначе webhook отклоняет запросы)');
    }
  } else {
    console.log(`✓ SMS Aero: обычные SMS, ${config.smsAeroEmail}, sign="${config.smsAeroSign}"`);
  }
} else if (config.smsRuApiId) {
  console.log('✓ SMS.ru: боевой режим');
} else {
  console.warn('⚠ SMS: SMS_MOCK=false, но SMS_AERO_EMAIL / SMS_AERO_API_KEY пустые — коды будут тестовыми');
}

if (config.adminEmailMock) {
  console.log('Admin email: тестовый режим (ADMIN_EMAIL_MOCK=true или не задан SMTP_HOST)');
} else if (config.smtp.host && config.smtp.user && config.smtp.pass) {
  console.log(`✓ Admin email SMTP: ${config.smtp.host}:${config.smtp.port} → ${config.adminEmail}`);
} else {
  console.warn('⚠ Admin email: ADMIN_EMAIL_MOCK=false, но SMTP не заполнен — вход в админку может не работать');
}

if (config.pushMock) {
  console.log('Push: тестовый режим (PUSH_MOCK=true или не задан FIREBASE_PROJECT_ID)');
} else if (config.firebase.projectId && config.firebase.clientEmail && config.firebase.privateKey) {
  console.log(`✓ Firebase push: project ${config.firebase.projectId}`);
} else {
  console.warn('⚠ Push: PUSH_MOCK=false, но Firebase ключи пустые — уведомления не уйдут');
}

const robokassaReady = Boolean(
  config.robokassa.merchantLogin &&
    config.robokassa.password1 &&
    config.robokassa.password2,
);
if (config.paymentMock) {
  console.log('Payments: тестовый режим (PAYMENT_MOCK=true)');
} else if (robokassaReady) {
  const modeLabel = config.robokassa.testMode
    ? 'тест (IsTest=1 — нужны тестовые пароли в кабинете)'
    : 'боевой';
  console.log(`✓ Payments: Робокасса ${modeLabel}, merchant=${config.robokassa.merchantLogin}, receipt=${config.robokassa.fiscalReceipt}`);
} else {
  console.warn('⚠ Payments: PAYMENT_MOCK=false, но ключи Робокассы пустые — оплата останется тестовой');
}

if (process.env.ADMIN_SECRET) {
  console.warn('⚠ ADMIN_SECRET устарел (I-C) — выплаты партнёрам только через admin token');
}

const visionMock = config.photoMockModeration || !config.visionApiKey;
if (visionMock) {
  if (!config.photoMockModeration && !config.visionApiKey) {
    console.warn('⚠ Vision: PHOTO_MOCK_MODERATION=false, но YC_VISION_API_KEY пуст — загрузка фото будет отклоняться');
  } else {
    console.log('Vision: тестовый режим (PHOTO_MOCK_MODERATION=true или не задан YC_VISION_API_KEY)');
  }
} else {
  console.log(
    `✓ Yandex Vision: moderation threshold ${config.visionModerationThreshold}` +
      (config.visionFolderId ? `, folder ${config.visionFolderId}` : ''),
  );
}

module.exports = config;
