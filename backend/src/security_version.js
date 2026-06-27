/** Метка версии безопасности — видна в GET /api/health (для проверки деплоя). */
module.exports = {
  stage: 'J-B',
  activeVerifySessionRequired: true,
  paymentStatusOwnerCheck: true,
  partnersNextCodeClosed: true,
  corsRestricted: true,
  userSessionAuth: true,
  legacyAdminSecretRemoved: true,
  apiRateLimit: true,
  apiRateLimitMax: 400,
  authRateLimitMax: 60,
};
