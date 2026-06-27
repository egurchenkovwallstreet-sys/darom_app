const config = require('../config');

function requireMobileIdWebhookSecret(req, res, next) {
  const secret = config.mobileIdWebhookSecret;

  // Без секрета — только явный dev-режим SMS_MOCK (J-D)
  if (!secret) {
    if (config.smsMock) {
      return next();
    }
    return res.status(503).json({
      error: 'Webhook Mobile ID не настроен: задайте MOBILE_ID_WEBHOOK_SECRET в backend/.env',
    });
  }

  const provided = String(
    req.query.secret ?? req.headers['x-mobile-id-webhook-secret'] ?? ''
  ).trim();

  if (provided !== secret) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  return next();
}

module.exports = { requireMobileIdWebhookSecret };
