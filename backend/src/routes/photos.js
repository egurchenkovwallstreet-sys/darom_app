const fs = require('fs');
const path = require('path');
const express = require('express');
const config = require('../config');
const { readFromS3 } = require('../utils/photo_storage');

const router = express.Router();
const FILE_NAME_RE = /^[a-zA-Z0-9._-]+\.(jpg|jpeg|png|webp)$/i;

async function sendListingPhoto(fileName, res) {
  if (config.photoStorage === 's3') {
    try {
      const { buffer, contentType } = await readFromS3(`listings/${fileName}`);
      res.set('Content-Type', contentType);
      res.set('Cache-Control', 'public, max-age=86400');
      return res.send(buffer);
    } catch (error) {
      const code = error?.name || error?.Code;
      if (code === 'NoSuchKey' || code === 'NotFound') {
        return res.status(404).json({ error: 'Фото не найдено' });
      }
      throw error;
    }
  }

  const filePath = path.join(config.uploadDir, fileName);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'Фото не найдено' });
  }

  return res.sendFile(filePath);
}

async function sendAvatarPhoto(fileName, res) {
  if (config.photoStorage === 's3') {
    try {
      const { buffer, contentType } = await readFromS3(`avatars/${fileName}`);
      res.set('Content-Type', contentType);
      res.set('Cache-Control', 'public, max-age=86400');
      return res.send(buffer);
    } catch (error) {
      const code = error?.name || error?.Code;
      if (code === 'NoSuchKey' || code === 'NotFound') {
        return res.status(404).json({ error: 'Аватар не найден' });
      }
      throw error;
    }
  }

  const filePath = path.join(config.uploadDir, 'avatars', fileName);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'Аватар не найден' });
  }

  return res.sendFile(filePath);
}

router.get('/listings/:fileName', async (req, res) => {
  const fileName = path.basename(req.params.fileName);
  if (!FILE_NAME_RE.test(fileName)) {
    return res.status(400).json({ error: 'Некорректное имя файла' });
  }

  try {
    return await sendListingPhoto(fileName, res);
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
    return await sendAvatarPhoto(fileName, res);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
