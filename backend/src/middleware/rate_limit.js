const rateLimit = require('express-rate-limit');

/** Лимиты на одного пользователя (один IP). Чаты опрашиваются раз в 1 с → ~120 req/min только на чаты. */
const API_GENERAL_MAX = 400;
const AUTH_GENERAL_MAX = 60;

function skipApiRateLimit(req) {
  return (
    req.path === '/health' ||
    req.path.startsWith('/deploy-web') ||
    req.path.startsWith('/deploy-backend')
  );
}

/** Общий лимит API: 400 запросов / мин / IP. */
const apiGeneralLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: API_GENERAL_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  skip: skipApiRateLimit,
  message: { error: 'Слишком много запросов. Подождите минуту.' },
});

/** Лимит на /api/auth/*: 60 запросов / мин / IP (Mobile ID poll ~30/min). */
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

module.exports = {
  apiGeneralLimiter,
  authGeneralLimiter,
  loginPinLimiter,
  smsSendLimiter,
  adminAuthStartLimiter,
};
