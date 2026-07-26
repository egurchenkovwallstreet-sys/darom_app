const crypto = require('crypto');
const { normalizePhone } = require('./phone');
const { generateCode, sendSmsCode, canSendRealSms } = require('../services/sms_service');
const { generateEmailCode, sendAdminEmailCode } = require('../services/email_service');
const {
  resolveVerifyProvider,
  startPhoneVerification,
  fetchVerifySession,
  syncMobileIdSessionStatus,
  buildPollPayload,
  confirmVerifyCode,
  MOBILE_ID_STATUS,
  FLASH_CALL_HINT,
} = require('./phone_verify_flow');
const config = require('../config');

const CHALLENGE_TTL_MIN = 10;
const SESSION_TTL_HOURS = 12;
const ADMIN_MOBILE_ID_PURPOSE = 'admin_login';

async function ensureSuperAdmin(db) {
  const phone = normalizePhone(config.adminPhone);
  const email = String(config.adminEmail || '').trim().toLowerCase();
  if (!phone || !email) return null;

  await db.query(
    `
    INSERT INTO admin_users (phone, email, role)
    VALUES ($1, $2, 'super_admin')
    ON CONFLICT (phone) DO UPDATE SET
      email = EXCLUDED.email,
      role = 'super_admin',
      is_active = TRUE
    `,
    [phone, email]
  );

  const result = await db.query(
    'SELECT id, phone, email, role FROM admin_users WHERE phone = $1 AND is_active = TRUE',
    [phone]
  );
  return result.rows[0] ?? null;
}

async function getLatestChallenge(db, adminId) {
  const challenge = await db.query(
    `
    SELECT id, sms_code, email_code, expires_at, mobile_id_session_id, phone_verified
    FROM admin_login_challenges
    WHERE admin_id = $1
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [adminId]
  );
  return challenge.rows[0] ?? null;
}

async function markAdminPhoneVerified(db, challengeId) {
  await db.query(
    'UPDATE admin_login_challenges SET phone_verified = TRUE WHERE id = $1',
    [challengeId]
  );
}

async function createAdminSession(db, admin) {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + SESSION_TTL_HOURS * 60 * 60 * 1000);

  await db.query(
    `
    INSERT INTO admin_sessions (token, admin_id, role, expires_at)
    VALUES ($1, $2, $3, $4)
    `,
    [token, admin.id, admin.role, expiresAt]
  );

  return {
    ok: true,
    token,
    role: admin.role,
    expires_at: expiresAt.toISOString(),
    admin: { phone: admin.phone, email: admin.email, role: admin.role },
  };
}

async function resolveAdminEmailDelivery(admin, phone, emailCode, emailResult) {
  if (!emailResult.error) {
    return {
      ok: true,
      email_mock: emailResult.mock ?? false,
      email_debug_code: emailResult.mock ? emailResult.debugCode ?? null : null,
      email_hint: admin.email.replace(/(.{2}).+(@.+)/, '$1***$2'),
      email_channel: emailResult.mock ? 'mock' : 'smtp',
      email_delivery_hint: null,
    };
  }

  if (
    emailResult.connectionBlocked &&
    config.adminEmailSmsFallback &&
    canSendRealSms()
  ) {
    try {
      const smsResult = await sendSmsCode(phone, emailCode, {
        mode: 'real',
        message: `Даром админ: код с почты ${emailCode}. Действует 10 мин.`,
      });
      console.warn('[ADMIN EMAIL] SMTP недоступен — код с почты отправлен SMS на admin-телефон');
      return {
        ok: true,
        email_mock: smsResult.mock ?? false,
        email_debug_code: smsResult.mock ? emailCode : null,
        email_hint: 'SMS на ваш admin-номер',
        email_channel: 'sms_fallback',
        email_delivery_hint:
          'Почта с сервера недоступна (Timeweb блокирует SMTP). Второй код (6 цифр) отправлен SMS.',
      };
    } catch (smsErr) {
      return {
        ok: false,
        error: smsErr.message || 'Не удалось отправить код ни на почту, ни SMS',
      };
    }
  }

  return {
    ok: false,
    error:
      emailResult.error ||
      'Не удалось отправить код на почту. Проверьте SMTP в backend/.env (см. deploy/SMTP.md)',
  };
}

async function startAdminLogin(db, phoneRaw) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа к админ-панели' };
  }

  const emailCode = generateEmailCode();
  const expiresAt = new Date(Date.now() + CHALLENGE_TTL_MIN * 60 * 1000);

  const verifyProvider = resolveVerifyProvider();
  if (verifyProvider === 'flash_call' || verifyProvider === 'mobile_id') {
    let emailResult;
    let phoneStarted;
    try {
      [emailResult, phoneStarted] = await Promise.all([
        sendAdminEmailCode({ to: admin.email, code: emailCode }),
        startPhoneVerification({
          verifyPhone: phone,
          accountPhone: phone,
          userId: null,
          purpose: ADMIN_MOBILE_ID_PURPOSE,
        }),
      ]);
    } catch (err) {
      return {
        ok: false,
        error: err.message || 'Не удалось отправить подтверждение на телефон. Попробуйте ещё раз.',
      };
    }

    if (!phoneStarted.ok || phoneStarted.mode === 'sms') {
      return {
        ok: false,
        error:
          'Подтверждение телефона недоступно. Задайте PLUSOFON_FLASH_ACCESS_TOKEN или SMS_AERO_MOBILE_ID_SIGN в backend/.env',
      };
    }

    const emailDelivery = await resolveAdminEmailDelivery(admin, phone, emailCode, emailResult);
    if (!emailDelivery.ok) {
      return { ok: false, error: emailDelivery.error };
    }

    await db.query(
      `
      INSERT INTO admin_login_challenges (
        admin_id, email_code, expires_at, mobile_id_session_id, phone_verified
      )
      VALUES ($1, $2, $3, $4, FALSE)
      `,
      [admin.id, emailCode, expiresAt, phoneStarted.session_token]
    );

    const mobileHint =
      phoneStarted.mode === 'flash_call'
        ? FLASH_CALL_HINT
        : 'На телефон может прийти запрос «Подтвердить» (SIM-PUSH) или SMS с кодом — это нормально.';
    const hintParts = [emailDelivery.email_delivery_hint, mobileHint].filter(Boolean);
    return {
      ok: true,
      mode: phoneStarted.mode,
      phone,
      session_token: phoneStarted.session_token,
      status: phoneStarted.status,
      status_label: phoneStarted.status_label,
      mock: phoneStarted.mock,
      debug_code: phoneStarted.debug_code,
      email_hint: emailDelivery.email_hint,
      challenge_expires_in: CHALLENGE_TTL_MIN * 60,
      email_mock: emailDelivery.email_mock,
      email_debug_code: emailDelivery.email_debug_code,
      email_channel: emailDelivery.email_channel,
      hint: hintParts.join(' '),
    };
  }

  if (!canSendRealSms()) {
    return {
      ok: false,
      error:
        'Подтверждение телефона и SMS не настроены. Проверьте PLUSOFON_FLASH_ACCESS_TOKEN или SMS_AERO_* в backend/.env',
    };
  }

  const smsCode = generateCode();
  let emailResult;
  let smsResult;
  try {
    [emailResult, smsResult] = await Promise.all([
      sendAdminEmailCode({ to: admin.email, code: emailCode }),
      sendSmsCode(phone, smsCode, { mode: 'real' }),
    ]);
  } catch (err) {
    return { ok: false, error: err.message || 'Не удалось отправить SMS' };
  }

  const emailDelivery = await resolveAdminEmailDelivery(admin, phone, emailCode, emailResult);
  if (!emailDelivery.ok) {
    return { ok: false, error: emailDelivery.error };
  }

  await db.query(
    `
    INSERT INTO admin_login_challenges (admin_id, sms_code, email_code, expires_at, phone_verified)
    VALUES ($1, $2, $3, $4, FALSE)
    `,
    [admin.id, smsCode, emailCode, expiresAt]
  );

  return {
    ok: true,
    mode: 'sms',
    phone,
    email_hint: emailDelivery.email_hint,
    challenge_expires_in: CHALLENGE_TTL_MIN * 60,
    sms_mock: smsResult.mock ?? false,
    sms_debug_code: smsResult.mock ? smsResult.debugCode ?? null : null,
    email_mock: emailDelivery.email_mock,
    email_debug_code: emailDelivery.email_debug_code,
    email_channel: emailDelivery.email_channel,
    hint: emailDelivery.email_delivery_hint,
  };
}

async function pollAdminMobileId(db, phoneRaw, sessionToken) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа' };
  }

  const session = await fetchVerifySession(String(sessionToken), phone, ADMIN_MOBILE_ID_PURPOSE);
  if (!session) {
    return { ok: false, error: 'Сессия не найдена' };
  }

  const status = await syncMobileIdSessionStatus(session);
  return { ok: true, ...buildPollPayload(session, status) };
}

async function completeAdminMobileIdPhone(db, phoneRaw, sessionToken) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа' };
  }

  const row = await getLatestChallenge(db, admin.id);
  if (!row || new Date(row.expires_at) < new Date()) {
    return { ok: false, error: 'Коды устарели. Запросите вход заново.' };
  }
  if (String(row.mobile_id_session_id) !== String(sessionToken)) {
    return { ok: false, error: 'Сессия не совпадает с текущим входом' };
  }

  const session = await fetchVerifySession(String(sessionToken), phone, ADMIN_MOBILE_ID_PURPOSE);
  if (!session) {
    return { ok: false, error: 'Сессия не найдена' };
  }

  if (session.provider === 'flash_call') {
    return {
      ok: false,
      error: 'Для звонка введите 4 цифры номера в форме подтверждения',
    };
  }

  const status = await syncMobileIdSessionStatus(session);
  if (Number(status) !== MOBILE_ID_STATUS.SUCCESS) {
    return { ok: false, error: 'Подтверждение ещё не завершено на телефоне' };
  }

  await markAdminPhoneVerified(db, row.id);
  return { ok: true, phone_verified: true };
}

async function confirmAdminMobileIdOtp(db, phoneRaw, sessionToken, code) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа' };
  }

  const row = await getLatestChallenge(db, admin.id);
  if (!row || new Date(row.expires_at) < new Date()) {
    return { ok: false, error: 'Коды устарели. Запросите вход заново.' };
  }
  if (String(row.mobile_id_session_id) !== String(sessionToken)) {
    return { ok: false, error: 'Сессия не совпадает с текущим входом' };
  }

  const session = await fetchVerifySession(String(sessionToken), phone, ADMIN_MOBILE_ID_PURPOSE);
  if (!session) {
    return { ok: false, error: 'Сессия не найдена' };
  }

  const check = await confirmVerifyCode(session, code);
  if (!check.ok) {
    return { ok: false, error: check.error };
  }

  await markAdminPhoneVerified(db, row.id);
  return { ok: true, phone_verified: true };
}

async function verifyAdminLogin(db, { phone: phoneRaw, smsCode, emailCode, sessionToken }) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа' };
  }

  const row = await getLatestChallenge(db, admin.id);
  if (!row || new Date(row.expires_at) < new Date()) {
    return { ok: false, error: 'Коды устарели. Запросите вход заново.' };
  }

  if (row.mobile_id_session_id) {
    if (!row.phone_verified) {
      return { ok: false, error: 'Сначала подтвердите телефон (звонок или SMS)' };
    }
    if (sessionToken && String(row.mobile_id_session_id) !== String(sessionToken)) {
      return { ok: false, error: 'Сессия не совпадает с текущим входом' };
    }
  } else {
    if (!smsCode) {
      return { ok: false, error: 'Нужен SMS-код' };
    }
    if (String(smsCode).trim() !== String(row.sms_code)) {
      return { ok: false, error: 'Неверный SMS-код' };
    }
  }

  if (!emailCode) {
    return { ok: false, error: 'Нужен код с почты' };
  }
  if (String(emailCode).trim() !== String(row.email_code)) {
    return { ok: false, error: 'Неверный код с почты' };
  }

  const session = await createAdminSession(db, admin);
  await db.query('DELETE FROM admin_login_challenges WHERE id = $1', [row.id]);
  return session;
}

async function getAdminSession(db, token) {
  if (!token) return null;

  const result = await db.query(
    `
    SELECT s.token, s.role, s.expires_at, a.id, a.phone, a.email, a.is_active
    FROM admin_sessions s
    JOIN admin_users a ON a.id = s.admin_id
    WHERE s.token = $1
    `,
    [token]
  );

  const row = result.rows[0];
  if (!row || !row.is_active || new Date(row.expires_at) < new Date()) {
    return null;
  }

  return {
    token: row.token,
    role: row.role,
    adminId: row.id,
    phone: row.phone,
    email: row.email,
  };
}

function requireAdminRole(session, allowedRoles) {
  if (!session) return false;
  return allowedRoles.includes(session.role);
}

async function checkAdminAccessByPhone(dbConn, phoneRaw) {
  const adminUser = await getAdminUserByPhone(dbConn, phoneRaw);
  return Boolean(adminUser);
}

async function getAdminUserByPhone(dbConn, phoneRaw) {
  const phone = normalizePhone(phoneRaw);
  if (!phone) return null;

  await ensureSuperAdmin(dbConn);

  const result = await dbConn.query(
    `
    SELECT id, phone, email, role
    FROM admin_users
    WHERE phone = $1 AND is_active = TRUE
    LIMIT 1
    `,
    [phone]
  );
  return result.rows[0] ?? null;
}

module.exports = {
  startAdminLogin,
  pollAdminMobileId,
  completeAdminMobileIdPhone,
  confirmAdminMobileIdOtp,
  verifyAdminLogin,
  getAdminSession,
  requireAdminRole,
  ensureSuperAdmin,
  checkAdminAccessByPhone,
  getAdminUserByPhone,
};
