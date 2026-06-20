const crypto = require('crypto');
const db = require('../db/pool');
const { normalizePhone } = require('./phone');
const { generateCode, sendSmsCode } = require('../services/sms_service');
const { generateEmailCode, sendAdminEmailCode } = require('../services/email_service');
const config = require('../config');

const CHALLENGE_TTL_MIN = 10;
const SESSION_TTL_HOURS = 12;

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

async function startAdminLogin(db, phoneRaw) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа к админ-панели' };
  }

  const smsCode = generateCode();
  const emailCode = generateEmailCode();
  const expiresAt = new Date(Date.now() + CHALLENGE_TTL_MIN * 60 * 1000);

  await db.query(
    `
    INSERT INTO admin_login_challenges (admin_id, sms_code, email_code, expires_at)
    VALUES ($1, $2, $3, $4)
    `,
    [admin.id, smsCode, emailCode, expiresAt]
  );

  const smsResult = await sendSmsCode(phone, smsCode);
  const emailResult = await sendAdminEmailCode({ to: admin.email, code: emailCode });

  return {
    ok: true,
    phone,
    email_hint: admin.email.replace(/(.{2}).+(@.+)/, '$1***$2'),
    challenge_expires_in: CHALLENGE_TTL_MIN * 60,
    sms_mock: smsResult.mock ?? false,
    sms_debug_code: smsResult.debugCode ?? null,
    email_mock: emailResult.mock ?? true,
    email_debug_code: emailResult.debugCode ?? null,
  };
}

async function verifyAdminLogin(db, { phone: phoneRaw, smsCode, emailCode }) {
  const phone = normalizePhone(phoneRaw);
  const admin = await ensureSuperAdmin(db);

  if (!admin || admin.phone !== phone) {
    return { ok: false, error: 'Нет доступа' };
  }

  const challenge = await db.query(
    `
    SELECT id, sms_code, email_code, expires_at
    FROM admin_login_challenges
    WHERE admin_id = $1
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [admin.id]
  );

  const row = challenge.rows[0];
  if (!row || new Date(row.expires_at) < new Date()) {
    return { ok: false, error: 'Коды устарели. Запросите вход заново.' };
  }

  if (String(smsCode).trim() !== String(row.sms_code)) {
    return { ok: false, error: 'Неверный SMS-код' };
  }
  if (String(emailCode).trim() !== String(row.email_code)) {
    return { ok: false, error: 'Неверный код с почты' };
  }

  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + SESSION_TTL_HOURS * 60 * 60 * 1000);

  await db.query(
    `
    INSERT INTO admin_sessions (token, admin_id, role, expires_at)
    VALUES ($1, $2, $3, $4)
    `,
    [token, admin.id, admin.role, expiresAt]
  );

  await db.query('DELETE FROM admin_login_challenges WHERE id = $1', [row.id]);

  return {
    ok: true,
    token,
    role: admin.role,
    expires_at: expiresAt.toISOString(),
    admin: { phone: admin.phone, email: admin.email, role: admin.role },
  };
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

module.exports = {
  startAdminLogin,
  verifyAdminLogin,
  getAdminSession,
  requireAdminRole,
  ensureSuperAdmin,
};
