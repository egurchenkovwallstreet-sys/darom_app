const config = require('../config');
const { canUseMobileId } = require('../services/mobile_id_service');

function requireMobileIdWebhookSecret(req, res, next) {
  const secret = config.mobileIdWebhookSecret;

  if (!secret) {
    if (!config.smsMock && canUseMobileId()) {
      return res.status(503).json({
        error: 'Webhook Mobile ID не настроен: задайте MOBILE_ID_WEBHOOK_SECRET в backend/.env',
      });
    }
    return next();
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
