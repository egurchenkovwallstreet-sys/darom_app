/** Метка версии безопасности — видна в GET /api/health (для проверки деплоя). */
module.exports = {
  stage: 'I-F',
  partnersNextCodeClosed: true,
  corsRestricted: true,
  userSessionAuth: true,
  legacyAdminSecretRemoved: true,
  apiRateLimit: true,
  apiRateLimitMax: 400,
  authRateLimitMax: 60,
};
