const express = require('express');
const crypto = require('crypto');
const db = require('../db/pool');
const { normalizePhone } = require('../utils/phone');
const { generateCode, sendSmsCode } = require('../services/sms_service');
const { hashPin, verifyPin } = require('../utils/pin_hash');
const config = require('../config');

const router = express.Router();

const CODE_TTL_MINUTES = 5;
const RESEND_COOLDOWN_SEC = 60;
const VERIFY_TOKEN_TTL_MINUTES = 15;
const PHONE_REVERIFY_DAYS = Number(process.env.PHONE_REVERIFY_DAYS) || 35;

function daysSince(dateValue) {
  if (!dateValue) return Infinity;
  const ms = Date.now() - new Date(dateValue).getTime();
  return ms / (1000 * 60 * 60 * 24);
}

function needsPhoneReverify(phoneVerifiedAt) {
  return daysSince(phoneVerifiedAt) >= PHONE_REVERIFY_DAYS;
}

async function fetchAuthUser(normalizedPhone) {
  const result = await db.query(
    `
    SELECT id, phone, name, pin_hash, phone_verified_at, pin_set_at,
           is_blocked_permanent, blocked_until
    FROM users
    WHERE phone = $1
    `,
    [normalizedPhone]
  );
  return result.rows[0] ?? null;
}

function isBlockedUser(user) {
  if (!user) return false;
  if (user.is_blocked_permanent) return true;
  if (user.blocked_until && new Date(user.blocked_until) > new Date()) return true;
  return false;
}

async function storeVerifyToken(normalizedPhone) {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + VERIFY_TOKEN_TTL_MINUTES * 60 * 1000);

  await db.query(
    `
    INSERT INTO phone_verify_tokens (phone, token, expires_at)
    VALUES ($1, $2, $3)
    ON CONFLICT (phone) DO UPDATE SET
      token = EXCLUDED.token,
      expires_at = EXCLUDED.expires_at,
      created_at = NOW()
    `,
    [normalizedPhone, token, expiresAt]
  );

  return { token, expires_in: VERIFY_TOKEN_TTL_MINUTES * 60 };
}

async function consumeVerifyToken(normalizedPhone, token) {
  const result = await db.query(
    'SELECT token, expires_at FROM phone_verify_tokens WHERE phone = $1',
    [normalizedPhone]
  );
  const row = result.rows[0];

  if (!row || row.token !== token) {
    return false;
  }

  if (new Date(row.expires_at) < new Date()) {
    await db.query('DELETE FROM phone_verify_tokens WHERE phone = $1', [normalizedPhone]);
    return false;
  }

  await db.query('DELETE FROM phone_verify_tokens WHERE phone = $1', [normalizedPhone]);
  return true;
}

async function sendCodeForPhone(normalizedPhone, res) {
  const code = generateCode();
  const expiresAt = new Date(Date.now() + CODE_TTL_MINUTES * 60 * 1000);

  const existing = await db.query(
    'SELECT created_at FROM sms_codes WHERE phone = $1',
    [normalizedPhone]
  );

  if (existing.rows[0]) {
    const secondsSince =
      (Date.now() - new Date(existing.rows[0].created_at).getTime()) / 1000;
    if (secondsSince < RESEND_COOLDOWN_SEC) {
      const wait = Math.ceil(RESEND_COOLDOWN_SEC - secondsSince);
      return res.status(429).json({
        error: `Подождите ${wait} сек. перед повторной отправкой`,
      });
    }
  }

  await db.query(
    `
    INSERT INTO sms_codes (phone, code, expires_at)
    VALUES ($1, $2, $3)
    ON CONFLICT (phone) DO UPDATE SET
      code = EXCLUDED.code,
      expires_at = EXCLUDED.expires_at,
      created_at = NOW()
    `,
    [normalizedPhone, code, expiresAt]
  );

  const sendResult = await sendSmsCode(normalizedPhone, code);

  const body = {
    ok: true,
    phone: normalizedPhone,
    expires_in: CODE_TTL_MINUTES * 60,
    mock: sendResult.mock,
  };

  if (sendResult.mock && config.smsMock) {
    body.debug_code = sendResult.debugCode;
  }

  return res.json(body);
}

// POST /api/auth/check-phone { phone }
router.post('/check-phone', async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchAuthUser(normalizedPhone);

    if (!user) {
      return res.json({
        phone: normalizedPhone,
        registered: false,
        has_pin: false,
        needs_sms: true,
        auth_method: 'sms_register',
        reverify_days: PHONE_REVERIFY_DAYS,
      });
    }

    if (isBlockedUser(user)) {
      return res.status(403).json({ error: 'Аккаунт заблокирован. Обратитесь в поддержку.' });
    }

    const hasPin = Boolean(user.pin_hash);
    const reverify = needsPhoneReverify(user.phone_verified_at);

    if (!hasPin || reverify) {
      return res.json({
        phone: normalizedPhone,
        registered: true,
        has_pin: hasPin,
        needs_sms: true,
        auth_method: hasPin ? 'sms_reverify' : 'sms_register',
        reverify_days: PHONE_REVERIFY_DAYS,
        user_name: user.name,
      });
    }

    return res.json({
      phone: normalizedPhone,
      registered: true,
      has_pin: true,
      needs_sms: false,
      auth_method: 'pin',
      reverify_days: PHONE_REVERIFY_DAYS,
      user_name: user.name,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/send-code { phone, purpose?: register|reverify }
router.post('/send-code', async (req, res) => {
  const { phone, purpose = 'register' } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchAuthUser(normalizedPhone);

    if (user && isBlockedUser(user)) {
      return res.status(403).json({ error: 'Аккаунт заблокирован. Обратитесь в поддержку.' });
    }

    const hasPin = Boolean(user?.pin_hash);
    const reverify = user ? needsPhoneReverify(user.phone_verified_at) : false;

    if (user && hasPin && !reverify && purpose !== 'reverify') {
      return res.status(400).json({
        error: 'Для входа используйте пароль из 4 цифр',
        auth_method: 'pin',
      });
    }

    if (user && hasPin && reverify && purpose !== 'reverify') {
      return res.status(400).json({
        error: `Подтвердите номер по SMS — прошло более ${PHONE_REVERIFY_DAYS} дней`,
        needs_reverify: true,
        auth_method: 'sms_reverify',
      });
    }

    return await sendCodeForPhone(normalizedPhone, res);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/verify-code { phone, code }
router.post('/verify-code', async (req, res) => {
  const { phone, code } = req.body;

  if (!phone || !code) {
    return res.status(400).json({ error: 'Нужны phone и code' });
  }

  const trimmedCode = String(code).trim();
  if (!/^\d{4}$/.test(trimmedCode)) {
    return res.status(400).json({ error: 'Код — 4 цифры' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);

    const result = await db.query(
      'SELECT code, expires_at FROM sms_codes WHERE phone = $1',
      [normalizedPhone]
    );
    const row = result.rows[0];

    if (!row) {
      return res.status(400).json({ error: 'Сначала запросите код' });
    }

    if (new Date(row.expires_at) < new Date()) {
      await db.query('DELETE FROM sms_codes WHERE phone = $1', [normalizedPhone]);
      return res.status(400).json({ error: 'Код истёк. Запросите новый' });
    }

    if (row.code !== trimmedCode) {
      return res.status(400).json({ error: 'Неверный код' });
    }

    await db.query('DELETE FROM sms_codes WHERE phone = $1', [normalizedPhone]);

    const user = await fetchAuthUser(normalizedPhone);
    const isNewUser = !user;

    await db.query(
      `
      UPDATE users SET phone_verified_at = NOW()
      WHERE phone = $1
      `,
      [normalizedPhone]
    );

    const tokenInfo = await storeVerifyToken(normalizedPhone);

    res.json({
      verified: true,
      phone: normalizedPhone,
      is_new_user: isNewUser,
      has_pin: Boolean(user?.pin_hash),
      user_name: user?.name ?? null,
      verification_token: tokenInfo.token,
      verification_expires_in: tokenInfo.expires_in,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/set-pin { phone, pin, verification_token }
router.post('/set-pin', async (req, res) => {
  const { phone, pin, verification_token: verificationToken } = req.body;

  if (!phone || !pin || !verificationToken) {
    return res.status(400).json({ error: 'Нужны phone, pin и verification_token' });
  }

  const trimmedPin = String(pin).trim();
  if (!/^\d{4}$/.test(trimmedPin)) {
    return res.status(400).json({ error: 'Пароль — 4 цифры' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const tokenOk = await consumeVerifyToken(normalizedPhone, verificationToken);

    if (!tokenOk) {
      return res.status(400).json({ error: 'Сессия подтверждения истекла. Запросите SMS-код снова' });
    }

    const pinHash = hashPin(trimmedPin);

    await db.query(
      `
      UPDATE users
      SET pin_hash = $2, pin_set_at = NOW(), phone_verified_at = NOW()
      WHERE phone = $1
      `,
      [normalizedPhone, pinHash]
    );

    res.json({ ok: true, phone: normalizedPhone });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/login-pin { phone, pin }
router.post('/login-pin', async (req, res) => {
  const { phone, pin } = req.body;

  if (!phone || !pin) {
    return res.status(400).json({ error: 'Нужны phone и pin' });
  }

  const trimmedPin = String(pin).trim();
  if (!/^\d{4}$/.test(trimmedPin)) {
    return res.status(400).json({ error: 'Пароль — 4 цифры' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchAuthUser(normalizedPhone);

    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден. Пройдите регистрацию' });
    }

    if (isBlockedUser(user)) {
      return res.status(403).json({ error: 'Аккаунт заблокирован. Обратитесь в поддержку.' });
    }

    if (!user.pin_hash) {
      return res.status(400).json({
        error: 'Пароль не задан. Подтвердите номер по SMS',
        auth_method: 'sms_register',
      });
    }

    if (needsPhoneReverify(user.phone_verified_at)) {
      return res.status(403).json({
        error: `Подтвердите номер по SMS — прошло более ${PHONE_REVERIFY_DAYS} дней`,
        needs_reverify: true,
        auth_method: 'sms_reverify',
      });
    }

    if (!verifyPin(trimmedPin, user.pin_hash)) {
      return res.status(401).json({ error: 'Неверный пароль' });
    }

    res.json({
      ok: true,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
