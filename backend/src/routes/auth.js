const express = require('express');
const db = require('../db/pool');
const { normalizePhone } = require('../utils/phone');
const { generateCode, sendSmsCode } = require('../services/sms_service');
const {
  STATUS: MOBILE_ID_STATUS,
  canUseMobileId,
  sendMobileIdAuth,
  verifyMobileIdOtp,
  fetchMobileIdStatus,
  isTerminalStatus,
  statusLabel,
} = require('../services/mobile_id_service');
const { canUsePlusofonFlash } = require('../services/plusofon_flash_service');
const { hashPin, verifyPin } = require('../utils/pin_hash');
const { storeVerifyToken, consumeVerifyToken } = require('../utils/phone_verify_token');
const { validateActivationCode } = require('../utils/partner_helpers');
const {
  createUserSession,
  formatSessionDbError,
  requireUserSession,
  rejectMismatchedPhone,
  revokeUserSession,
  revokeAllUserSessions,
} = require('../middleware/user_auth');
const {
  loginPinLimiter,
  smsSendLimiter,
  checkPhoneLimiter,
  verifyCodeLimiter,
} = require('../middleware/rate_limit');
const { requireMobileIdWebhookSecret } = require('../middleware/mobile_id_webhook');
const { setSessionCookie, clearSessionCookie } = require('../utils/session_cookie');
const { readVerifySessionToken } = require('../utils/verify_session_token');
const {
  startPhoneVerification,
  fetchVerifySession,
  syncMobileIdSessionStatus,
  buildPollPayload,
  confirmVerifyCode,
} = require('../utils/phone_verify_flow');
const config = require('../config');

const router = express.Router();

const CODE_TTL_MINUTES = 5;
const RESEND_COOLDOWN_SEC = 60;

function smsModeForPurpose(purpose) {
  if (purpose === 'active_verify') {
    return 'real';
  }
  return 'mock';
}

const PIN_LOCKOUT_ATTEMPTS = 5;
const PIN_LOCKOUT_MINUTES = 15;

async function fetchAuthUser(normalizedPhone) {
  const result = await db.query(
    `
    SELECT id, phone, name, pin_hash, phone_verified_at, pin_set_at,
           real_phone_verified_at, is_blocked_permanent, blocked_until,
           pin_failed_attempts, pin_locked_until
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

async function storeSmsCode(normalizedPhone, res, smsMode) {
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

  const sendResult = await sendSmsCode(normalizedPhone, code, { mode: smsMode });

  const body = {
    ok: true,
    phone: normalizedPhone,
    expires_in: CODE_TTL_MINUTES * 60,
    mock: sendResult.mock,
  };

  if (sendResult.mock && sendResult.debugCode) {
    body.debug_code = sendResult.debugCode;
  }

  return res.json(body);
}

async function verifySmsCode(normalizedPhone, trimmedCode) {
  const result = await db.query(
    'SELECT code, expires_at FROM sms_codes WHERE phone = $1',
    [normalizedPhone]
  );
  const row = result.rows[0];

  if (!row) {
    return { ok: false, status: 400, error: 'Сначала запросите код' };
  }

  if (new Date(row.expires_at) < new Date()) {
    await db.query('DELETE FROM sms_codes WHERE phone = $1', [normalizedPhone]);
    return { ok: false, status: 400, error: 'Код истёк. Запросите новый' };
  }

  if (row.code !== trimmedCode) {
    return { ok: false, status: 400, error: 'Неверный код' };
  }

  await db.query('DELETE FROM sms_codes WHERE phone = $1', [normalizedPhone]);
  return { ok: true };
}

async function loadActiveVerifyUser(accountPhoneRaw, verifyPhoneRaw) {
  const accountPhone = normalizePhone(accountPhoneRaw);
  const verifyPhone = normalizePhone(verifyPhoneRaw);
  const user = await fetchAuthUser(accountPhone);

  if (!user) {
    return { error: { status: 404, message: 'Пользователь не найден' } };
  }
  if (isBlockedUser(user)) {
    return { error: { status: 403, message: 'Аккаунт заблокирован. Обратитесь в поддержку.' } };
  }
  if (user.real_phone_verified_at) {
    return { error: { status: 400, message: 'Номер уже подтверждён' } };
  }
  if (verifyPhone !== accountPhone) {
    const taken = await fetchAuthUser(verifyPhone);
    if (taken && taken.id !== user.id) {
      return { error: { status: 400, message: 'Этот номер уже используется другим аккаунтом' } };
    }
  }

  return { user, accountPhone, verifyPhone };
}

async function finalizeRealPhoneVerify(user, verifyPhone, accountPhone) {
  await db.query(
    `
    UPDATE users
    SET phone = $2, phone_verified_at = NOW(), real_phone_verified_at = NOW()
    WHERE id = $1
    `,
    [user.id, verifyPhone]
  );

  return {
    ok: true,
    phone: verifyPhone,
    real_phone_verified: true,
    phone_changed: verifyPhone !== accountPhone,
    message: 'Теперь вам доступны все функции приложения!',
  };
}

async function loadPartnerVerifyContext(phoneRaw, partnerCodeRaw) {
  const phone = normalizePhone(phoneRaw);
  const validation = await validateActivationCode(db, partnerCodeRaw);
  if (!validation.ok) {
    return { error: { status: 400, message: validation.error } };
  }

  const existing = await fetchAuthUser(phone);
  if (existing) {
    return { error: { status: 400, message: 'Этот номер уже зарегистрирован' } };
  }

  return { phone, partnerCode: validation.code };
}

async function finalizePartnerVerify(session) {
  const validation = await validateActivationCode(db, session.partner_activation_code);
  if (!validation.ok) {
    throw new Error(validation.error);
  }

  const existing = await fetchAuthUser(session.verify_phone);
  if (existing) {
    throw new Error('Этот номер уже зарегистрирован');
  }

  const tokenInfo = await storeVerifyToken(session.verify_phone);
  return {
    ok: true,
    phone: session.verify_phone,
    partner_activation_code: session.partner_activation_code,
    verification_token: tokenInfo.token,
    verification_expires_in: tokenInfo.expires_in,
    real_phone_verified: true,
  };
}

async function finalizeResetPinVerify(session) {
  const user = await fetchAuthUser(session.verify_phone);
  if (!user || !user.pin_hash) {
    throw new Error('Сначала пройдите регистрацию');
  }
  if (isBlockedUser(user)) {
    throw new Error('Аккаунт заблокирован. Обратитесь в поддержку.');
  }

  await db.query(
    `
    UPDATE users SET phone_verified_at = NOW()
    WHERE id = $1
    `,
    [user.id]
  );

  const tokenInfo = await storeVerifyToken(session.verify_phone);
  return {
    ok: true,
    phone: session.verify_phone,
    verification_token: tokenInfo.token,
    verification_expires_in: tokenInfo.expires_in,
    message: 'Номер подтверждён. Задайте новый пароль из 4 цифр.',
  };
}

async function fetchMobileIdSession(sessionToken, accountPhone, purpose = 'active_verify') {
  return fetchVerifySession(sessionToken, accountPhone, purpose);
}

// POST /api/auth/check-phone { phone } — без user_name (J-C: не светить имя посторонним)
router.post('/check-phone', checkPhoneLimiter, async (req, res) => {
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
        needs_sms: false,
        auth_method: 'register',
      });
    }

    if (isBlockedUser(user)) {
      return res.status(403).json({ error: 'Аккаунт заблокирован. Обратитесь в поддержку.' });
    }

    const hasPin = Boolean(user.pin_hash);

    if (!hasPin) {
      return res.json({
        phone: normalizedPhone,
        registered: true,
        has_pin: false,
        needs_sms: false,
        auth_method: 'register',
      });
    }

    return res.json({
      phone: normalizedPhone,
      registered: true,
      has_pin: true,
      needs_sms: false,
      auth_method: 'pin',
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/send-code { phone, purpose?: register|reset_pin|partner }
router.post('/send-code', smsSendLimiter, async (req, res) => {
  const { phone, purpose = 'register' } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  if (!['register', 'reset_pin', 'partner'].includes(purpose)) {
    return res.status(400).json({ error: 'Неверный purpose' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchAuthUser(normalizedPhone);

    if (user && isBlockedUser(user)) {
      return res.status(403).json({ error: 'Аккаунт заблокирован. Обратитесь в поддержку.' });
    }

    const hasPin = Boolean(user?.pin_hash);

    if (purpose === 'register') {
      if (user && hasPin) {
        return res.status(400).json({
          error: 'Для входа используйте пароль из 4 цифр',
          auth_method: 'pin',
        });
      }
    } else if (purpose === 'reset_pin') {
      if (!user || !hasPin) {
        return res.status(400).json({ error: 'Сначала пройдите регистрацию' });
      }
      return res.status(400).json({
        error: 'Для восстановления пароля подтвердите номер через приложение (Flash Call)',
      });
    } else if (purpose === 'partner') {
      if (user) {
        return res.status(400).json({ error: 'Этот номер уже зарегистрирован' });
      }
      return res.status(400).json({
        error: 'Для партнёров используйте Mobile ID: POST /api/auth/partner-verify/send',
      });
    }

    return await storeSmsCode(normalizedPhone, res, smsModeForPurpose(purpose));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/verify-code { phone, code, purpose?: register|reset_pin|partner }
router.post('/verify-code', verifyCodeLimiter, async (req, res) => {
  const { phone, code, purpose = 'register' } = req.body;

  if (!phone || !code) {
    return res.status(400).json({ error: 'Нужны phone и code' });
  }

  const trimmedCode = String(code).trim();
  if (!/^\d{4}$/.test(trimmedCode)) {
    return res.status(400).json({ error: 'Код — 4 цифры' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const check = await verifySmsCode(normalizedPhone, trimmedCode);

    if (!check.ok) {
      return res.status(check.status).json({ error: check.error });
    }

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
      real_phone_verified: purpose === 'partner',
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

    const updated = await db.query(
      `
      UPDATE users
      SET pin_hash = $2, pin_set_at = NOW(), phone_verified_at = NOW()
      WHERE phone = $1
      RETURNING id, name
      `,
      [normalizedPhone, pinHash]
    );

    const sessionInfo = await createUserSession(updated.rows[0].id);
    const row = updated.rows[0];

    setSessionCookie(res, sessionInfo.token);

    res.json({
      ok: true,
      phone: normalizedPhone,
      session_token: sessionInfo.token,
      expires_at: sessionInfo.expires_at,
      user: {
        id: row.id,
        phone: normalizedPhone,
        name: row.name,
      },
    });
  } catch (error) {
    res.status(500).json({ error: formatSessionDbError(error) });
  }
});

// POST /api/auth/login-pin { phone, pin }
router.post('/login-pin', loginPinLimiter, async (req, res) => {
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
        error: 'Пароль не задан. Завершите регистрацию с экрана ввода номера',
        auth_method: 'register',
      });
    }

    if (user.pin_locked_until && new Date(user.pin_locked_until) > new Date()) {
      const waitMin = Math.max(
        1,
        Math.ceil((new Date(user.pin_locked_until).getTime() - Date.now()) / 60000)
      );
      return res.status(429).json({
        error: `Слишком много неверных попыток. Подождите ${waitMin} мин.`,
      });
    }

    if (!verifyPin(trimmedPin, user.pin_hash)) {
      const nextAttempts = Number(user.pin_failed_attempts ?? 0) + 1;
      if (nextAttempts >= PIN_LOCKOUT_ATTEMPTS) {
        await db.query(
          `
          UPDATE users
          SET pin_failed_attempts = 0,
              pin_locked_until = NOW() + ($2 || ' minutes')::interval
          WHERE id = $1
          `,
          [user.id, String(PIN_LOCKOUT_MINUTES)]
        );
      } else {
        await db.query('UPDATE users SET pin_failed_attempts = $2 WHERE id = $1', [
          user.id,
          nextAttempts,
        ]);
      }
      return res.status(401).json({ error: 'Неверный пароль' });
    }

    await db.query(
      'UPDATE users SET pin_failed_attempts = 0, pin_locked_until = NULL WHERE id = $1',
      [user.id]
    );

    const sessionInfo = await createUserSession(user.id);

    setSessionCookie(res, sessionInfo.token);

    res.json({
      ok: true,
      session_token: sessionInfo.token,
      expires_at: sessionInfo.expires_at,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        real_phone_verified: Boolean(user.real_phone_verified_at),
      },
    });
  } catch (error) {
    res.status(500).json({ error: formatSessionDbError(error) });
  }
});

// POST /api/auth/logout — отозвать текущую сессию (J-C)
router.post('/logout', requireUserSession, async (req, res) => {
  try {
    await revokeUserSession(req.userSession.token);
    clearSessionCookie(res);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/logout-all — выйти на всех устройствах, кроме текущего (J-C)
router.post('/logout-all', requireUserSession, async (req, res) => {
  try {
    await revokeAllUserSessions(req.userSession.userId, req.userSession.token);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/active-verify/send { phone, verify_phone } — только владелец сессии (J-B)
router.post('/active-verify/send', requireUserSession, async (req, res) => {
  const { phone, verify_phone: verifyPhoneRaw } = req.body;

  if (!phone || !verifyPhoneRaw) {
    return res.status(400).json({ error: 'Нужны phone и verify_phone' });
  }
  if (!rejectMismatchedPhone(req, res, phone)) {
    return;
  }

  try {
    const ctx = await loadActiveVerifyUser(phone, verifyPhoneRaw);
    if (ctx.error) {
      return res.status(ctx.error.status).json({ error: ctx.error.message });
    }

    const { user, accountPhone, verifyPhone } = ctx;

    const started = await startPhoneVerification({
      verifyPhone,
      accountPhone,
      userId: user.id,
      purpose: 'active_verify',
    });

    if (started.mode === 'sms') {
      return await storeSmsCode(verifyPhone, res, smsModeForPurpose('active_verify'));
    }

    return res.json(started);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/auth/active-verify/poll?phone= — токен в X-Verify-Session-Token
router.get('/active-verify/poll', requireUserSession, async (req, res) => {
  const { phone } = req.query;
  const sessionToken = readVerifySessionToken(req, { allowQuery: true });

  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и X-Verify-Session-Token' });
  }
  if (!rejectMismatchedPhone(req, res, phone)) {
    return;
  }

  try {
    const accountPhone = normalizePhone(String(phone));
    const session = await fetchVerifySession(String(sessionToken), accountPhone);
    if (!session) {
      return res.status(404).json({ error: 'Сессия не найдена' });
    }

    const status = await syncMobileIdSessionStatus(session);
    res.json(buildPollPayload(session, status));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/active-verify/complete { phone } — токен в X-Verify-Session-Token
router.post('/active-verify/complete', requireUserSession, async (req, res) => {
  const { phone } = req.body ?? {};
  const sessionToken = readVerifySessionToken(req, { allowBody: true });

  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и X-Verify-Session-Token' });
  }
  if (!rejectMismatchedPhone(req, res, phone)) {
    return;
  }

  try {
    const accountPhone = normalizePhone(phone);
    const session = await fetchVerifySession(String(sessionToken), accountPhone);
    if (!session) {
      return res.status(404).json({ error: 'Сессия не найдена' });
    }

    if (session.provider === 'flash_call') {
      return res.status(400).json({
        error: 'Для звонка введите 4 цифры номера в форме подтверждения',
      });
    }

    const status = await syncMobileIdSessionStatus(session);
    if (Number(status) !== MOBILE_ID_STATUS.SUCCESS) {
      return res.status(400).json({ error: 'Подтверждение ещё не завершено на телефоне' });
    }

    const user = await fetchAuthUser(accountPhone);
    if (!user || user.id !== session.user_id) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const body = await finalizeRealPhoneVerify(user, session.verify_phone, accountPhone);
    res.json(body);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/partner-verify/send { phone, partner_activation_code }
router.post('/partner-verify/send', async (req, res) => {
  const { phone, partner_activation_code: partnerCodeRaw } = req.body;

  if (!phone || !partnerCodeRaw) {
    return res.status(400).json({ error: 'Нужны phone и partner_activation_code' });
  }

  try {
    const ctx = await loadPartnerVerifyContext(phone, partnerCodeRaw);
    if (ctx.error) {
      return res.status(ctx.error.status).json({ error: ctx.error.message });
    }

    if (!canUseMobileId() && !canUsePlusofonFlash()) {
      return res.status(503).json({
        error:
          'Верификация не настроена. Задайте PLUSOFON_FLASH_ACCESS_TOKEN или SMS_AERO_MOBILE_ID_SIGN в backend/.env',
      });
    }

    const { phone: verifyPhone, partnerCode } = ctx;
    const started = await startPhoneVerification({
      verifyPhone,
      accountPhone: verifyPhone,
      userId: null,
      purpose: 'partner',
      partnerCode,
    });

    if (started.mode === 'sms') {
      return res.status(503).json({ error: 'Подтверждение партнёра недоступно без Flash Call или Mobile ID' });
    }

    return res.json(started);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/auth/partner-verify/poll?phone=
router.get('/partner-verify/poll', async (req, res) => {
  const { phone } = req.query;
  const sessionToken = readVerifySessionToken(req, { allowQuery: true });

  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и X-Verify-Session-Token' });
  }

  try {
    const normalizedPhone = normalizePhone(String(phone));
    const session = await fetchVerifySession(String(sessionToken), normalizedPhone, 'partner');
    if (!session) {
      return res.status(404).json({ error: 'Сессия не найдена' });
    }

    const status = await syncMobileIdSessionStatus(session);
    res.json(buildPollPayload(session, status));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/partner-verify/complete { phone }
router.post('/partner-verify/complete', async (req, res) => {
  const { phone } = req.body ?? {};
  const sessionToken = readVerifySessionToken(req, { allowBody: true });

  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и X-Verify-Session-Token' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const session = await fetchVerifySession(String(sessionToken), normalizedPhone, 'partner');
    if (!session) {
      return res.status(404).json({ error: 'Сессия не найдена' });
    }

    if (session.provider === 'flash_call') {
      return res.status(400).json({
        error: 'Для звонка введите 4 цифры номера в форме подтверждения',
      });
    }

    const status = await syncMobileIdSessionStatus(session);
    if (Number(status) !== MOBILE_ID_STATUS.SUCCESS) {
      return res.status(400).json({ error: 'Подтверждение ещё не завершено на телефоне' });
    }

    const body = await finalizePartnerVerify(session);
    res.json(body);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/partner-verify/confirm { phone, code }
router.post('/partner-verify/confirm', async (req, res) => {
  const { phone, code } = req.body ?? {};
  const sessionToken = readVerifySessionToken(req, { allowBody: true });

  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и X-Verify-Session-Token' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const session = await fetchVerifySession(String(sessionToken), normalizedPhone, 'partner');
    if (!session) {
      return res.status(404).json({ error: 'Сессия не найдена' });
    }

    const trimmedCode = String(code ?? '').trim();
    const check = await confirmVerifyCode(session, trimmedCode);
    if (!check.ok) {
      return res.status(check.status).json({ error: check.error });
    }

    const body = await finalizePartnerVerify(session);
    res.json(body);
  } catch (error) {
    const message = error.message || 'Ошибка подтверждения';
    res.status(500).json({ error: message });
  }
});

// POST /api/auth/reset-pin/send { phone } — восстановление пароля через Flash Call / Mobile ID
router.post('/reset-pin/send', smsSendLimiter, async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchAuthUser(normalizedPhone);

    if (!user || !user.pin_hash) {
      return res.status(400).json({ error: 'Сначала пройдите регистрацию' });
    }
    if (isBlockedUser(user)) {
      return res.status(403).json({ error: 'Аккаунт заблокирован. Обратитесь в поддержку.' });
    }

    if (!canUseMobileId() && !canUsePlusofonFlash()) {
      return res.status(503).json({
        error:
          'Верификация не настроена. Задайте PLUSOFON_FLASH_ACCESS_TOKEN или SMS_AERO_MOBILE_ID_SIGN в backend/.env',
      });
    }

    const started = await startPhoneVerification({
      verifyPhone: normalizedPhone,
      accountPhone: normalizedPhone,
      userId: user.id,
      purpose: 'reset_pin',
    });

    if (started.mode === 'sms') {
      return res.status(503).json({
        error: 'Восстановление пароля недоступно без Flash Call или Mobile ID',
      });
    }

    return res.json(started);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/auth/reset-pin/poll?phone=
router.get('/reset-pin/poll', async (req, res) => {
  const { phone } = req.query;
  const sessionToken = readVerifySessionToken(req, { allowQuery: true });

  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и X-Verify-Session-Token' });
  }

  try {
    const normalizedPhone = normalizePhone(String(phone));
    const session = await fetchVerifySession(String(sessionToken), normalizedPhone, 'reset_pin');
    if (!session) {
      return res.status(404).json({ error: 'Сессия не найдена' });
    }

    const status = await syncMobileIdSessionStatus(session);
    res.json(buildPollPayload(session, status));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/reset-pin/complete { phone }
router.post('/reset-pin/complete', async (req, res) => {
  const { phone } = req.body ?? {};
  const sessionToken = readVerifySessionToken(req, { allowBody: true });

  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и X-Verify-Session-Token' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const session = await fetchVerifySession(String(sessionToken), normalizedPhone, 'reset_pin');
    if (!session) {
      return res.status(404).json({ error: 'Сессия не найдена' });
    }

    if (session.provider === 'flash_call') {
      return res.status(400).json({
        error: 'Для звонка введите 4 цифры номера в форме подтверждения',
      });
    }

    const status = await syncMobileIdSessionStatus(session);
    if (Number(status) !== MOBILE_ID_STATUS.SUCCESS) {
      return res.status(400).json({ error: 'Подтверждение ещё не завершено на телефоне' });
    }

    const body = await finalizeResetPinVerify(session);
    res.json(body);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/reset-pin/confirm { phone, code }
router.post('/reset-pin/confirm', async (req, res) => {
  const { phone, code } = req.body ?? {};
  const sessionToken = readVerifySessionToken(req, { allowBody: true });

  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и X-Verify-Session-Token' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const session = await fetchVerifySession(String(sessionToken), normalizedPhone, 'reset_pin');
    if (!session) {
      return res.status(404).json({ error: 'Сессия не найдена' });
    }

    const trimmedCode = String(code ?? '').trim();
    const check = await confirmVerifyCode(session, trimmedCode);
    if (!check.ok) {
      return res.status(check.status).json({ error: check.error });
    }

    const body = await finalizeResetPinVerify(session);
    res.json(body);
  } catch (error) {
    const message = error.message || 'Ошибка подтверждения';
    res.status(500).json({ error: message });
  }
});

// POST /api/auth/mobile-id/webhook — SMS Aero Mobile ID
router.post('/mobile-id/webhook', requireMobileIdWebhookSecret, async (req, res) => {
  const { id, status } = req.body ?? {};

  if (id == null || status == null) {
    return res.status(400).json({ error: 'Нужны id и status' });
  }

  try {
    await db.query(
      `
      UPDATE mobile_id_sessions
      SET status = $2, updated_at = NOW()
      WHERE aero_id = $1
      `,
      [Number(id), Number(status)]
    );
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/active-verify/confirm { phone, verify_phone, code }
router.post('/active-verify/confirm', requireUserSession, async (req, res) => {
  const { phone, verify_phone: verifyPhoneRaw, code } = req.body ?? {};
  const sessionToken = readVerifySessionToken(req, { allowBody: true });

  if (!phone || !verifyPhoneRaw) {
    return res.status(400).json({ error: 'Нужны phone и verify_phone' });
  }
  if (!rejectMismatchedPhone(req, res, phone)) {
    return;
  }

  try {
    const ctx = await loadActiveVerifyUser(phone, verifyPhoneRaw);
    if (ctx.error) {
      return res.status(ctx.error.status).json({ error: ctx.error.message });
    }

    const { user, accountPhone, verifyPhone } = ctx;

    if (sessionToken) {
      const session = await fetchVerifySession(String(sessionToken), accountPhone);
      if (!session) {
        return res.status(404).json({ error: 'Сессия не найдена' });
      }

      const trimmedCode = String(code ?? '').trim();
      const check = await confirmVerifyCode(session, trimmedCode);
      if (!check.ok) {
        return res.status(check.status).json({ error: check.error });
      }

      const body = await finalizeRealPhoneVerify(user, verifyPhone, accountPhone);
      return res.json(body);
    }

    if (!code) {
      return res.status(400).json({ error: 'Нужен code' });
    }

    const trimmedCode = String(code).trim();
    if (!/^\d{4}$/.test(trimmedCode)) {
      return res.status(400).json({ error: 'Код — 4 цифры' });
    }

    const check = await verifySmsCode(verifyPhone, trimmedCode);
    if (!check.ok) {
      return res.status(check.status).json({ error: check.error });
    }

    const body = await finalizeRealPhoneVerify(user, verifyPhone, accountPhone);
    res.json(body);
  } catch (error) {
    const message = error.message || 'Ошибка подтверждения';
    if (message.includes('invalid otp')) {
      return res.status(400).json({ error: 'Неверный код из SMS' });
    }
    res.status(500).json({ error: message });
  }
});

module.exports = router;
