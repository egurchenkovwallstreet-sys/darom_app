const crypto = require('crypto');

const COMMISSION_PERCENT = Number(process.env.PARTNER_COMMISSION_PERCENT) || 30;
const PUBLIC_CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function normalizePartnerCode(code) {
  return String(code ?? '').trim().toUpperCase();
}

function generatePartnerPublicCode(length = 8) {
  let result = '';
  for (let i = 0; i < length; i += 1) {
    const index = crypto.randomInt(0, PUBLIC_CODE_CHARS.length);
    result += PUBLIC_CODE_CHARS[index];
  }
  return result;
}

async function generateUniquePartnerPublicCode(db) {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const code = generatePartnerPublicCode();
    const exists = await db.query(
      'SELECT 1 FROM users WHERE partner_public_code = $1',
      [code]
    );
    if (exists.rowCount === 0) {
      return code;
    }
  }
  throw new Error('Не удалось сгенерировать код партнёра');
}

async function findPartnerByPublicCode(db, code) {
  const normalized = normalizePartnerCode(code);
  if (!normalized) return null;

  const result = await db.query(
    `
    SELECT id, name, partner_public_code
    FROM users
    WHERE is_partner = TRUE AND partner_public_code = $1
    `,
    [normalized]
  );
  return result.rows[0] ?? null;
}

async function getActivationCode(db, code) {
  const normalized = normalizePartnerCode(code);
  if (!normalized) return null;

  const result = await db.query(
    `
    SELECT code, label, used_by_user_id, used_at
    FROM partner_activation_codes
    WHERE code = $1
    `,
    [normalized]
  );
  return result.rows[0] ?? null;
}

async function validateActivationCode(db, code) {
  const row = await getActivationCode(db, code);
  if (!row) {
    return { ok: false, error: 'Неверный код партнёра' };
  }
  if (row.used_by_user_id) {
    return { ok: false, error: 'Этот код уже использован' };
  }
  return { ok: true, code: row.code, label: row.label };
}

function calcCommission(amountRub) {
  return Math.floor((amountRub * COMMISSION_PERCENT) / 100);
}

async function recordPartnerPayment(db, userId, paymentType, amountRub) {
  const userResult = await db.query(
    'SELECT referred_by_partner_id FROM users WHERE id = $1',
    [userId]
  );
  const partnerId = userResult.rows[0]?.referred_by_partner_id;
  if (!partnerId) return null;

  const commission = calcCommission(amountRub);

  const inserted = await db.query(
    `
    INSERT INTO partner_payments (
      user_id, partner_id, payment_type, amount_rub, partner_commission_rub
    )
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id, partner_commission_rub
    `,
    [userId, partnerId, paymentType, amountRub, commission]
  );

  return inserted.rows[0];
}

async function fetchPartnerStats(db, partnerId) {
  const usersResult = await db.query(
    `
    SELECT COUNT(*)::int AS referred_users
    FROM users
    WHERE referred_by_partner_id = $1
    `,
    [partnerId]
  );

  const paymentsResult = await db.query(
    `
    SELECT
      COUNT(*)::int AS payments_count,
      COALESCE(SUM(amount_rub), 0)::int AS total_payments_rub,
      COALESCE(SUM(partner_commission_rub), 0)::int AS payout_rub
    FROM partner_payments
    WHERE partner_id = $1
    `,
    [partnerId]
  );

  const partnerResult = await db.query(
    `
    SELECT partner_public_code
    FROM users
    WHERE id = $1 AND is_partner = TRUE
    `,
    [partnerId]
  );

  return {
    referred_users: usersResult.rows[0]?.referred_users ?? 0,
    payments_count: paymentsResult.rows[0]?.payments_count ?? 0,
    total_payments_rub: paymentsResult.rows[0]?.total_payments_rub ?? 0,
    payout_rub: paymentsResult.rows[0]?.payout_rub ?? 0,
    commission_percent: COMMISSION_PERCENT,
    partner_public_code: partnerResult.rows[0]?.partner_public_code ?? null,
  };
}

module.exports = {
  COMMISSION_PERCENT,
  normalizePartnerCode,
  generateUniquePartnerPublicCode,
  findPartnerByPublicCode,
  validateActivationCode,
  recordPartnerPayment,
  fetchPartnerStats,
  calcCommission,
};
