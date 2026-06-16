const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const config = require('../config');
const { buildPhotoUrl } = require('./photo_urls');

function ensureUploadDir() {
  if (!fs.existsSync(config.uploadDir)) {
    fs.mkdirSync(config.uploadDir, { recursive: true });
  }
  return config.uploadDir;
}

function extensionForMime(mimeType) {
  if (mimeType === 'image/png') return 'png';
  if (mimeType === 'image/webp') return 'webp';
  return 'jpg';
}

function getS3PublicUrl(fileName) {
  const base = (config.s3.publicBaseUrl || `${config.s3.endpoint}/${config.s3.bucket}`)
    .replace(/\/$/, '');
  return `${base}/listings/${fileName}`;
}

function assertS3Configured() {
  if (!config.s3.bucket || !config.s3.accessKey || !config.s3.secretKey) {
    throw new Error(
      'Yandex Object Storage не настроен. Заполните YC_S3_BUCKET, YC_S3_ACCESS_KEY, YC_S3_SECRET_KEY в backend/.env'
    );
  }
}

async function saveToS3(buffer, fileName, mimeType) {
  assertS3Configured();

  const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

  const client = new S3Client({
    region: config.s3.region,
    endpoint: config.s3.endpoint,
    credentials: {
      accessKeyId: config.s3.accessKey,
      secretAccessKey: config.s3.secretKey,
    },
    forcePathStyle: true,
  });

  await client.send(
    new PutObjectCommand({
      Bucket: config.s3.bucket,
      Key: `listings/${fileName}`,
      Body: buffer,
      ContentType: mimeType,
      ACL: 'public-read',
    })
  );

  return getS3PublicUrl(fileName);
}

async function savePhoto(buffer, mimeType) {
  const ext = extensionForMime(mimeType);
  const fileName = `${Date.now()}-${crypto.randomBytes(8).toString('hex')}.${ext}`;

  if (config.photoStorage === 's3') {
    await saveToS3(buffer, fileName, mimeType);
    return buildPhotoUrl(fileName);
  }

  const dir = ensureUploadDir();
  const filePath = path.join(dir, fileName);
  fs.writeFileSync(filePath, buffer);
  return buildPhotoUrl(fileName);
}

async function saveAvatar(buffer, mimeType, userId) {
  const ext = extensionForMime(mimeType);
  const fileName = `${userId}.${ext}`;

  if (config.photoStorage === 's3') {
    assertS3Configured();
    const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
    const client = new S3Client({
      region: config.s3.region,
      endpoint: config.s3.endpoint,
      credentials: {
        accessKeyId: config.s3.accessKey,
        secretAccessKey: config.s3.secretKey,
      },
      forcePathStyle: true,
    });
    await client.send(
      new PutObjectCommand({
        Bucket: config.s3.bucket,
        Key: `avatars/${fileName}`,
        Body: buffer,
        ContentType: mimeType,
        ACL: 'public-read',
      })
    );
  } else {
    const dir = path.join(config.uploadDir, 'avatars');
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(path.join(dir, fileName), buffer);
  }

  const { buildAvatarUrl } = require('./photo_urls');
  return buildAvatarUrl(fileName);
}

module.exports = { ensureUploadDir, savePhoto, saveAvatar, getS3PublicUrl };
