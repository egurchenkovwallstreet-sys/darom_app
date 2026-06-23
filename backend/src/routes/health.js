const express = require('express');
const db = require('../db/pool');
const config = require('../config');

const router = express.Router();

router.get('/', async (_req, res) => {
  try {
    const dbInfo = await db.checkConnection();
    const s3Ready =
      config.photoStorage === 's3' &&
      Boolean(config.s3.bucket && config.s3.accessKey && config.s3.secretKey);

    const smtpConfigured = Boolean(
      config.smtp.host && config.smtp.user && config.smtp.pass
    );
    const pushConfigured = Boolean(
      config.firebase.projectId &&
        config.firebase.clientEmail &&
        config.firebase.privateKey
    );
    const visionConfigured = Boolean(config.visionApiKey);
    const visionMock = config.photoMockModeration || !visionConfigured;

    res.json({
      ok: true,
      service: 'darom-api',
      photos: {
        mode: config.photoStorage,
        s3Ready,
        bucket: config.s3.bucket || null,
      },
      vision: {
        mock: visionMock,
        configured: visionConfigured,
        ready: visionMock || visionConfigured,
        threshold: config.visionModerationThreshold,
      },
      adminEmail: {
        mock: config.adminEmailMock,
        smtpConfigured,
        ready: config.adminEmailMock || smtpConfigured,
      },
      push: {
        mock: config.pushMock,
        configured: pushConfigured,
        ready: config.pushMock || pushConfigured,
      },
      db: {
        connected: true,
        time: dbInfo.now,
        postgis: dbInfo.postgis,
      },
    });
  } catch (error) {
    res.status(503).json({
      ok: false,
      service: 'darom-api',
      db: { connected: false },
      error: error.message,
    });
  }
});

module.exports = router;
