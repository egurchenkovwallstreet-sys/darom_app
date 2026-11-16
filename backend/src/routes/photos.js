const fs = require('fs');
const path = require('path');
const express = require('express');
const sharp = require('sharp');
const config = require('../config');
const { readFromS3 } = require('../utils/photo_storage');

const router = express.Router();
const FILE_NAME_RE = /^[a-zA-Z0-9._-]+\.(jpg|jpeg|png|webp)$/i;

const DEFAULT_LISTING_MAX = Number.parseInt(process.env.PHOTO_WEB_MAX_W || '768', 10);

function parseMaxWidth(req) {
  const raw = req.query.w ?? req.query.width ?? req.query.full;
  if (raw === '0' || raw === 'full' || raw === 'original') return null;
  const w = Number.parseInt(String(raw ?? DEFAULT_LISTING_MAX), 10);
  if (!Number.isFinite(w) || w < 1) return DEFAULT_LISTING_MAX;
  return Math.min(w, 1600);
}

async function maybeResizeBuffer(buffer, maxWidth) {
  if (!maxWidth) return { buffer, contentType: null };
  try {
    const out = await sharp(buffer)
      .rotate()
      .resize(maxWidth, maxWidth, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 82, mozjpeg: true })
      .toBuffer();
    return { buffer: out, contentType: 'image/jpeg' };
  } catch (_) {
    return { buffer, contentType: null };
  }
}

async function sendListingPhoto(fileName, res, maxWidth) {
  if (config.photoStorage === 's3') {
    try {
      let { buffer, contentType } = await readFromS3(`listings/${fileName}`);
      const resized = await maybeResizeBuffer(buffer, maxWidth);
      buffer = resized.buffer;
      if (resized.contentType) contentType = resized.contentType;
      res.set('Content-Type', contentType);
      res.set(
        'Cache-Control',
        maxWidth ? 'public, max-age=604800, immutable' : 'public, max-age=86400'
      );
      res.set('X-Content-Type-Options', 'nosniff');
      res.set('Content-Disposition', `inline; filename="${fileName.replace(/"/g, '')}"`);
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

  if (!maxWidth) {
    return res.sendFile(filePath);
  }

  const buffer = fs.readFileSync(filePath);
  const resized = await maybeResizeBuffer(buffer, maxWidth);
  res.set('Content-Type', resized.contentType || 'image/jpeg');
  res.set('Cache-Control', 'public, max-age=604800, immutable');
  return res.send(resized.buffer);
}

async function sendAvatarPhoto(fileName, res, maxWidth) {
  if (config.photoStorage === 's3') {
    try {
      let { buffer, contentType } = await readFromS3(`avatars/${fileName}`);
      const resized = await maybeResizeBuffer(buffer, maxWidth);
      buffer = resized.buffer;
      if (resized.contentType) contentType = resized.contentType;
      res.set('Content-Type', contentType);
      res.set(
        'Cache-Control',
        maxWidth ? 'public, max-age=604800, immutable' : 'public, max-age=86400'
      );
      res.set('X-Content-Type-Options', 'nosniff');
      res.set('Content-Disposition', `inline; filename="${fileName.replace(/"/g, '')}"`);
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

  if (!maxWidth) {
    return res.sendFile(filePath);
  }

  const buffer = fs.readFileSync(filePath);
  const resized = await maybeResizeBuffer(buffer, maxWidth);
  res.set('Content-Type', resized.contentType || 'image/jpeg');
  res.set('Cache-Control', 'public, max-age=604800, immutable');
  return res.send(resized.buffer);
}

router.get('/listings/:fileName', async (req, res) => {
  const fileName = path.basename(req.params.fileName);
  if (!FILE_NAME_RE.test(fileName)) {
    return res.status(400).json({ error: 'Некорректное имя файла' });
  }

  const maxWidth = parseMaxWidth(req);

  try {
    return await sendListingPhoto(fileName, res, maxWidth);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

router.get('/avatars/:fileName', async (req, res) => {
  const fileName = path.basename(req.params.fileName);
  if (!FILE_NAME_RE.test(fileName)) {
    return res.status(400).json({ error: 'Некорректное имя файла' });
  }

  const maxWidth = parseMaxWidth(req);

  try {
    return await sendAvatarPhoto(fileName, res, maxWidth);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
