const fs = require('fs');
const path = require('path');
const express = require('express');
const config = require('../config');

const router = express.Router();
const FILE_NAME_RE = /^[a-zA-Z0-9._-]+\.(jpg|jpeg|png|webp)$/i;

router.get('/listings/:fileName', async (req, res) => {
  const fileName = path.basename(req.params.fileName);
  if (!FILE_NAME_RE.test(fileName)) {
    return res.status(400).json({ error: 'Некорректное имя файла' });
  }

  try {
    if (config.photoStorage === 's3') {
      const url = `${config.s3.endpoint}/${config.s3.bucket}/listings/${fileName}`;
      const upstream = await fetch(url);
      if (!upstream.ok) {
        return res.status(upstream.status).json({ error: 'Фото не найдено' });
      }

      res.set('Content-Type', upstream.headers.get('content-type') || 'image/jpeg');
      res.set('Cache-Control', 'public, max-age=86400');
      return res.send(Buffer.from(await upstream.arrayBuffer()));
    }

    const filePath = path.join(config.uploadDir, fileName);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'Фото не найдено' });
    }

    return res.sendFile(filePath);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

router.get('/avatars/:fileName', async (req, res) => {
  const fileName = path.basename(req.params.fileName);
  if (!FILE_NAME_RE.test(fileName)) {
    return res.status(400).json({ error: 'Некорректное имя файла' });
  }

  try {
    if (config.photoStorage === 's3') {
      const url = `${config.s3.endpoint}/${config.s3.bucket}/avatars/${fileName}`;
      const upstream = await fetch(url);
      if (!upstream.ok) {
        return res.status(upstream.status).json({ error: 'Аватар не найден' });
      }

      res.set('Content-Type', upstream.headers.get('content-type') || 'image/jpeg');
      res.set('Cache-Control', 'public, max-age=86400');
      return res.send(Buffer.from(await upstream.arrayBuffer()));
    }

    const filePath = path.join(config.uploadDir, 'avatars', fileName);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'Аватар не найден' });
    }

    return res.sendFile(filePath);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
