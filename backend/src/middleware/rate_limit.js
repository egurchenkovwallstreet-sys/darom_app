const rateLimit = require('express-rate-limit');

function skipApiRateLimit(req) {
  return (
    req.path === '/health' ||
    req.path.startsWith('/deploy-web') ||
    req.path.startsWith('/deploy-backend')
  );
}

/** Общий лимит API: 100 запросов / мин / IP (I-F). */
const apiGeneralLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  skip: skipApiRateLimit,
  message: { error: 'Слишком много запросов. Подождите минуту.' },
});

/** Лимит на /api/auth/*: 20 запросов / мин / IP (I-F). */
const authGeneralLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
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
