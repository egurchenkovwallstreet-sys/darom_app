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

    res.json({
      ok: true,
      service: 'darom-api',
      photos: {
        mode: config.photoStorage,
        s3Ready,
        bucket: config.s3.bucket || null,
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
