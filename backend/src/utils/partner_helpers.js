const COMMISSION_PERCENT = Number(process.env.PARTNER_COMMISSION_PERCENT) || 30;
const MAX_PARTNER_SEQUENCE = 1000;

function normalizePartnerCode(code) {
  const digits = String(code ?? '').replace(/\D/g, '');
  if (!digits) return null;

  const num = parseInt(digits, 10);
  if (!Number.isFinite(num) || num < 1 || num > MAX_PARTNER_SEQUENCE) {
    return null;
  }

  return String(num).padStart(4, '0');
}

async function getNextAvailableActivationCode(db) {
  const result = await db.query(
    `
    SELECT code, sequence_num, label
    FROM partner_activation_codes
    WHERE used_by_user_id IS NULL
    ORDER BY sequence_num ASC NULLS LAST, code ASC
    LIMIT 1
    `
  );
  return result.rows[0] ?? null;
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
    SELECT code, label, used_by_user_id, used_at, sequence_num
    FROM partner_activation_codes
    WHERE code = $1
    `,
    [normalized]
  );
  return result.rows[0] ?? null;
}

async function validateActivationCode(db, code) {
  const normalized = normalizePartnerCode(code);
  if (!normalized) {
    return { ok: false, error: 'Код партнёра: 4 цифры от 0001 до 1000' };
  }

  const row = await getActivationCode(db, normalized);
  if (!row) {
    return { ok: false, error: 'Неверный код партнёра' };
  }
  if (row.used_by_user_id) {
    return { ok: false, error: 'Этот код уже использован' };
  }

  const next = await getNextAvailableActivationCode(db);
  if (!next) {
    return { ok: false, error: 'Коды партнёров закончились (лимит 1000)' };
  }
  if (next.code !== normalized) {
    return {
      ok: false,
      error: `Сейчас активен код ${next.code}. Следующий откроется после регистрации предыдущего партнёра`,
    };
  }

  return { ok: true, code: row.code, label: row.label, sequence_num: row.sequence_num };
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

async function fetchPartnerCodeStatus(db) {
  const next = await getNextAvailableActivationCode(db);
  const usedResult = await db.query(
    `
    SELECT COUNT(*)::int AS used_count
    FROM partner_activation_codes
    WHERE used_by_user_id IS NOT NULL
    `
  );

  return {
    next_code: next?.code ?? null,
    next_sequence: next?.sequence_num ?? null,
    used_count: usedResult.rows[0]?.used_count ?? 0,
    total_codes: MAX_PARTNER_SEQUENCE,
    remaining: next ? MAX_PARTNER_SEQUENCE - (usedResult.rows[0]?.used_count ?? 0) : 0,
  };
}

module.exports = {
  COMMISSION_PERCENT,
  MAX_PARTNER_SEQUENCE,
  normalizePartnerCode,
  getNextAvailableActivationCode,
  findPartnerByPublicCode,
  validateActivationCode,
  recordPartnerPayment,
  fetchPartnerStats,
  fetchPartnerCodeStatus,
  calcCommission,
};
