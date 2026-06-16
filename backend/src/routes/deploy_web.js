const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFile } = require('child_process');
const { promisify } = require('util');
const config = require('../config');

const execFileAsync = promisify(execFile);
const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 80 * 1024 * 1024 },
});

router.post('/', upload.single('archive'), async (req, res) => {
  if (!config.deploySecret) {
    return res.status(503).json({ ok: false, error: 'DEPLOY_SECRET не настроен на сервере' });
  }

  const secret = req.headers['x-deploy-secret'];
  if (!secret || secret !== config.deploySecret) {
    return res.status(403).json({ ok: false, error: 'Forbidden' });
  }

  if (!req.file) {
    return res.status(400).json({ ok: false, error: 'Нужен файл archive (tar.gz)' });
  }

  const tmpDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), 'darom-web-'));
  const archivePath = path.join(tmpDir, 'web-build.tar.gz');

  try {
    await fs.promises.writeFile(archivePath, req.file.buffer);
    await fs.promises.mkdir(config.webRoot, { recursive: true });

    const entries = await fs.promises.readdir(config.webRoot);
    await Promise.all(
      entries.map((name) =>
        fs.promises.rm(path.join(config.webRoot, name), { recursive: true, force: true }),
      ),
    );

    await execFileAsync('tar', ['-xzf', archivePath, '-C', config.webRoot]);

    const files = await fs.promises.readdir(config.webRoot);
    console.log(`✓ Deploy web: ${files.length} files → ${config.webRoot}`);
    res.json({ ok: true, files: files.length, path: config.webRoot });
  } catch (err) {
    console.error('deploy-web error:', err);
    res.status(500).json({ ok: false, error: err.message });
  } finally {
    await fs.promises.rm(tmpDir, { recursive: true, force: true });
  }
});

module.exports = router;
