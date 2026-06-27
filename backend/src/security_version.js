/** Метка версии безопасности — видна в GET /api/health (для проверки деплоя). */
module.exports = {
  stage: 'J-C',
  activeVerifySessionRequired: true,
  paymentStatusOwnerCheck: true,
  checkPhoneRateLimit: true,
  checkPhoneNoUserName: true,
  pinAccountLockout: true,
  sessionLogout: true,
  verifyCodeRateLimit: true,
  partnersNextCodeClosed: true,
  corsRestricted: true,
  userSessionAuth: true,
  legacyAdminSecretRemoved: true,
  apiRateLimit: true,
  apiRateLimitMax: 400,
  authRateLimitMax: 60,
};
