const express = require('express');
const config = require('../config');

const router = express.Router();

// GET /api/config/firebase — публичные ключи для Flutter Web (без секретов)
router.get('/firebase', (_req, res) => {
  const fb = config.firebase;
  const configured = Boolean(
    fb.projectId && fb.webApiKey && fb.webAppId && fb.messagingSenderId && fb.webVapidKey
  );

  if (!configured) {
    return res.json({ configured: false });
  }

  res.json({
    configured: true,
    project_id: fb.projectId,
    api_key: fb.webApiKey,
    app_id: fb.webAppId,
    messaging_sender_id: fb.messagingSenderId,
    vapid_key: fb.webVapidKey,
  });
});

module.exports = router;
