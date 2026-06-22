const crypto = require('crypto');
const { normalizePhone } = require('./phone');
const { generateCode, sendSmsCode, canSendRealSms } = require('../services/sms_service');
const { generateEmailCode, sendAdminEmailCode } = require('../services/email_service');
const {
  STATUS: MOBILE_ID_STATUS,
  canUseMobileId,
  sendMobileIdAuth,
  verifyMobileIdOtp,
  fetchMobileIdStatus,
  isTerminalStatus,
  statusLabel,
} = require('../services/mobile_id_service');
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

async function fetchAdminMobileIdSession(db, sessionToken, phone) {
  const result = await db.query(
    `
    SELECT id, aero_id, account_phone, verify_phone, status
    FROM mobile_id_sessions
    WHERE id = $1 AND account_phone = $2 AND purpose = $3
    `,
    [sessionToken, normalizePhone(phone), ADMIN_MOBILE_ID_PURPOSE]
  );
  return result.rows[0] ?? null;
}

async function syncMobileIdSessionStatus(db, sessionRow) {
  if (!sessionRow) return null;
  let status = Number(sessionRow.status);
  if (status === MOBILE_ID_STATUS.NEED_OTP || isTerminalStatus(status)) {
    return status;
  }

  try {
    const remote = await fetchMobileIdStatus(sessionRow.aero_id);
    status = Number(remote.status);
    await db.query(
      'UPDATE mobile_id_sessions SET status = $2, updated_at = NOW() WHERE id = $1',
      [sessionRow.id, status]
    );
  } catch (_) {}

  return status;
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

async function startAdminLogin(db, phoneRaw) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа к админ-панели' };
  }

  const emailCode = generateEmailCode();
  const expiresAt = new Date(Date.now() + CHALLENGE_TTL_MIN * 60 * 1000);
  const emailResult = await sendAdminEmailCode({ to: admin.email, code: emailCode });

  if (emailResult.error) {
    return {
      ok: false,
      error: 'Не удалось отправить код на почту. Проверьте SMTP в backend/.env (см. deploy/SMTP.md)',
    };
  }

  if (canUseMobileId()) {
    const aeroData = await sendMobileIdAuth(phone);
    const sessionInsert = await db.query(
      `
      INSERT INTO mobile_id_sessions (
        aero_id, user_id, account_phone, verify_phone, status, purpose
      )
      VALUES ($1, NULL, $2, $2, $3, $4)
      RETURNING id
      `,
      [aeroData.id, phone, Number(aeroData.status) || 0, ADMIN_MOBILE_ID_PURPOSE]
    );

    await db.query(
      `
      INSERT INTO admin_login_challenges (
        admin_id, email_code, expires_at, mobile_id_session_id, phone_verified
      )
      VALUES ($1, $2, $3, $4, FALSE)
      `,
      [admin.id, emailCode, expiresAt, sessionInsert.rows[0].id]
    );

    const status = Number(aeroData.status) || 0;
    return {
      ok: true,
      mode: 'mobile_id',
      phone,
      session_token: sessionInsert.rows[0].id,
      status,
      status_label: statusLabel(status),
      email_hint: admin.email.replace(/(.{2}).+(@.+)/, '$1***$2'),
      challenge_expires_in: CHALLENGE_TTL_MIN * 60,
      email_mock: emailResult.mock ?? true,
      email_debug_code: emailResult.mock ? emailResult.debugCode ?? null : null,
      hint:
        'На телефон может прийти запрос «Подтвердить» (SIM-PUSH) или SMS с кодом — это нормально.',
    };
  }

  if (!canSendRealSms()) {
    return {
      ok: false,
      error:
        'Mobile ID и SMS не настроены. Проверьте SMS_AERO_* и SMS_AERO_MOBILE_ID_SIGN в backend/.env',
    };
  }

  const smsCode = generateCode();
  await db.query(
    `
    INSERT INTO admin_login_challenges (admin_id, sms_code, email_code, expires_at, phone_verified)
    VALUES ($1, $2, $3, $4, FALSE)
    `,
    [admin.id, smsCode, emailCode, expiresAt]
  );

  const smsResult = await sendSmsCode(phone, smsCode, { mode: 'real' });

  return {
    ok: true,
    mode: 'sms',
    phone,
    email_hint: admin.email.replace(/(.{2}).+(@.+)/, '$1***$2'),
    challenge_expires_in: CHALLENGE_TTL_MIN * 60,
    sms_mock: smsResult.mock ?? false,
    sms_debug_code: smsResult.mock ? smsResult.debugCode ?? null : null,
    email_mock: emailResult.mock ?? true,
    email_debug_code: emailResult.mock ? emailResult.debugCode ?? null : null,
  };
}

async function pollAdminMobileId(db, phoneRaw, sessionToken) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа' };
  }

  const session = await fetchAdminMobileIdSession(db, String(sessionToken), phone);
  if (!session) {
    return { ok: false, error: 'Сессия не найдена' };
  }

  const status = await syncMobileIdSessionStatus(db, session);
  const numericStatus = Number(status);

  return {
    ok: true,
    status: numericStatus,
    status_label: statusLabel(numericStatus),
    needs_otp: numericStatus === MOBILE_ID_STATUS.NEED_OTP,
    verified: numericStatus === MOBILE_ID_STATUS.SUCCESS,
    failed: [MOBILE_ID_STATUS.FAILED, MOBILE_ID_STATUS.ERROR].includes(numericStatus),
  };
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

  const session = await fetchAdminMobileIdSession(db, String(sessionToken), phone);
  if (!session) {
    return { ok: false, error: 'Сессия не найдена' };
  }

  const status = await syncMobileIdSessionStatus(db, session);
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

  const session = await fetchAdminMobileIdSession(db, String(sessionToken), phone);
  if (!session) {
    return { ok: false, error: 'Сессия не найдена' };
  }

  const trimmedCode = String(code ?? '').trim();
  if (!/^\d{4,8}$/.test(trimmedCode)) {
    return { ok: false, error: 'Введите код из SMS' };
  }

  await verifyMobileIdOtp({ aeroId: session.aero_id, code: trimmedCode });
  const status = await syncMobileIdSessionStatus(db, session);
  if (Number(status) !== MOBILE_ID_STATUS.SUCCESS) {
    return { ok: false, error: 'Код не принят. Попробуйте ещё раз' };
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
      return { ok: false, error: 'Сначала подтвердите телефон через Mobile ID' };
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
  const phone = normalizePhone(phoneRaw);
  if (!phone) return false;

  await ensureSuperAdmin(dbConn);

  const result = await dbConn.query(
    'SELECT 1 FROM admin_users WHERE phone = $1 AND is_active = TRUE LIMIT 1',
    [phone]
  );
  return (result.rowCount ?? 0) > 0;
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
};
