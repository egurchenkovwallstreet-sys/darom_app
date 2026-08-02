const rateLimit = require('express-rate-limit');
const { readSessionCookie } = require('../utils/session_cookie');

/** Лимиты на одного пользователя (сессия) или IP. Чаты опрашиваются раз в 1 с; фото ленты — отдельные GET. */
const API_GENERAL_MAX = 2000;
const AUTH_GENERAL_MAX = 120;

function getRateLimitKey(req) {
  const cookieToken = readSessionCookie(req);
  if (cookieToken) {
    return `session:${cookieToken.slice(0, 24)}`;
  }

  const header = req.headers.authorization;
  if (header?.startsWith('Bearer ')) {
    const token = header.slice(7).trim();
    if (token) return `session:${token.slice(0, 24)}`;
  }

  const userToken = req.headers['x-user-token'];
  if (userToken) {
    return `session:${String(userToken).slice(0, 24)}`;
  }

  return `ip:${req.ip}`;
}

function skipApiRateLimit(req) {
  return (
    req.path === '/health' ||
    (req.method === 'GET' && req.path.startsWith('/photos/'))
  );
}

/** Общий лимит API: 2000 запросов / мин / сессия или IP (фото и health не считаются). */
const apiGeneralLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: API_GENERAL_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  skip: skipApiRateLimit,
  keyGenerator: getRateLimitKey,
  validate: { keyGenerator: false },
  message: { error: 'Слишком много запросов. Подождите минуту.' },
});

/** Лимит на /api/auth/*: 120 запросов / мин / IP (poll verify ~30/min). */
const authGeneralLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: AUTH_GENERAL_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много запросов авторизации. Подождите минуту.' },
});

const loginPinLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много попыток входа. Подождите 15 минут.' },
});

const smsSendLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много запросов SMS. Подождите 15 минут.' },
});

const adminAuthStartLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много попыток входа в админку. Подождите 15 минут.' },
});

/** Перебор номеров через check-phone (J-C). */
const checkPhoneLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много проверок номера. Подождите 15 минут.' },
});

/** Brute-force SMS-кода (J-C). */
const verifyCodeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 15,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много попыток ввода кода. Подождите 15 минут.' },
});

/** Перебор кодов партнёра (J-C). */
const partnerCodeValidateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много проверок кода. Подождите 15 минут.' },
});

/** Анти-спам: создание обращений в поддержку. */
const supportCreateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много обращений. Подождите час.' },
});

/** Лимит сообщений в поддержку. */
const supportMessageLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много сообщений. Подождите час.' },
});

/** Brute-force кода с почты при входе в админку (J-H). */
const adminAuthVerifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много попыток ввода кода. Подождите 15 минут.' },
});

/** Flash Call / Mobile ID шаги админ-входа (J-H). */
const adminMobileIdStepLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много запросов подтверждения. Подождите 15 минут.' },
});

/** Деплой с GitHub Actions — не более 5 раз в час с одного IP (J-H). */
const deployLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Слишком много запросов деплоя. Подождите час.' },
});

module.exports = {
  apiGeneralLimiter,
  authGeneralLimiter,
  loginPinLimiter,
  smsSendLimiter,
  adminAuthStartLimiter,
  adminAuthVerifyLimiter,
  adminMobileIdStepLimiter,
  deployLimiter,
  checkPhoneLimiter,
  verifyCodeLimiter,
  partnerCodeValidateLimiter,
  supportCreateLimiter,
  supportMessageLimiter,
};
