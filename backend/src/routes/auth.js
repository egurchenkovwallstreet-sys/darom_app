const express = require('express');
const db = require('../db/pool');
const { normalizePhone } = require('../utils/phone');
const { generateCode, sendSmsCode } = require('../services/sms_service');
const config = require('../config');

const router = express.Router();

const CODE_TTL_MINUTES = 5;
const RESEND_COOLDOWN_SEC = 60;

// POST /api/auth/send-code { phone }
router.post('/send-code', async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const code = generateCode();
    const expiresAt = new Date(Date.now() + CODE_TTL_MINUTES * 60 * 1000);

    const existing = await db.query(
      'SELECT created_at FROM sms_codes WHERE phone = $1',
      [normalizedPhone],
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
      [normalizedPhone, code, expiresAt],
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

    res.json(body);
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
      [normalizedPhone],
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

    res.json({ verified: true, phone: normalizedPhone });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
