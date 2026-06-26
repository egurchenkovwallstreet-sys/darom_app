/** Метка версии безопасности — видна в GET /api/health (для проверки деплоя). */
module.exports = {
  stage: 'I-C',
  partnersNextCodeClosed: true,
  corsRestricted: true,
  userSessionAuth: true,
  legacyAdminSecretRemoved: true,
};
