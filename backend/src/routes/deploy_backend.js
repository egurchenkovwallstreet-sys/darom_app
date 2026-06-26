const express = require('express');
const path = require('path');
const { execFile } = require('child_process');
const { promisify } = require('util');
const config = require('../config');

const execFileAsync = promisify(execFile);
const router = express.Router();

router.post('/', async (req, res) => {
  if (!config.deploySecret) {
    return res.status(503).json({ ok: false, error: 'DEPLOY_SECRET не настроен на сервере' });
  }

  const secret = req.headers['x-deploy-secret'];
  if (!secret || secret !== config.deploySecret) {
    return res.status(403).json({ ok: false, error: 'Forbidden' });
  }

  const scriptPath = path.join(__dirname, '..', '..', 'scripts', 'deploy_backend.sh');

  try {
    const { stdout, stderr } = await execFileAsync('bash', [scriptPath], {
      cwd: path.join(__dirname, '..', '..', '..'),
      timeout: 5 * 60 * 1000,
      maxBuffer: 2 * 1024 * 1024,
    });

    if (stderr) {
      console.warn('deploy-backend stderr:', stderr);
    }
    console.log('deploy-backend stdout:', stdout);

    res.json({
      ok: true,
      message: 'Backend обновлён',
      log: stdout.slice(-4000),
    });
  } catch (err) {
    console.error('deploy-backend error:', err);
    res.status(500).json({
      ok: false,
      error: err.message,
      log: String(err.stdout || err.stderr || '').slice(-4000),
    });
  }
});

module.exports = router;
