const crypto = require('crypto');

const ITERATIONS = 120_000;
const KEY_LEN = 32;
const DIGEST = 'sha256';

function hashPin(pin) {
  const normalized = String(pin).trim();
  if (!/^\d{4}$/.test(normalized)) {
    throw new Error('Пароль — 4 цифры');
  }

  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto
    .pbkdf2Sync(normalized, salt, ITERATIONS, KEY_LEN, DIGEST)
    .toString('hex');

  return `${salt}:${hash}`;
}

function verifyPin(pin, storedHash) {
  if (!storedHash || typeof storedHash !== 'string') {
    return false;
  }

  const normalized = String(pin).trim();
  if (!/^\d{4}$/.test(normalized)) {
    return false;
  }

  const [salt, expectedHex] = storedHash.split(':');
  if (!salt || !expectedHex) {
    return false;
  }

  const actualHex = crypto
    .pbkdf2Sync(normalized, salt, ITERATIONS, KEY_LEN, DIGEST)
    .toString('hex');

  try {
    return crypto.timingSafeEqual(
      Buffer.from(expectedHex, 'hex'),
      Buffer.from(actualHex, 'hex')
    );
  } catch {
    return false;
  }
}

module.exports = { hashPin, verifyPin };
