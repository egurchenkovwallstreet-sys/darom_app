const { fetchPartnerCodeStatus, markPartnerPayoutComplete } = require('./partner_helpers');

function periodSql(column, period) {
  switch (period) {
    case 'day':
      return `${column} >= NOW() - INTERVAL '1 day'`;
    case 'week':
      return `${column} >= NOW() - INTERVAL '7 days'`;
    case 'month':
      return `${column} >= NOW() - INTERVAL '30 days'`;
    default:
      return 'TRUE';
  }
}

async function fetchPlatformStats(db, period = 'all') {
  const where = periodSql('created_at', period);

  const users = await db.query(
    `SELECT COUNT(*)::int AS cnt FROM users WHERE ${where}`
  );
  const listings = await db.query(
    `SELECT COUNT(*)::int AS cnt FROM listings WHERE status = 'active' AND ${where}`
  );
  const payments = await db.query(
    `
    SELECT
      COUNT(*)::int AS payments_count,
      COALESCE(SUM(amount_rub), 0)::int AS payments_rub
    FROM partner_payments
    WHERE ${periodSql('created_at', period)}
    `
  );

  const superDonor = await db.query(
    `
    SELECT COUNT(*)::int AS cnt
    FROM users
    WHERE super_donor_until IS NOT NULL
      AND super_donor_until > NOW()
    `
  );

  return {
    period,
    users_count: users.rows[0]?.cnt ?? 0,
    active_listings: listings.rows[0]?.cnt ?? 0,
    payments_count: payments.rows[0]?.payments_count ?? 0,
    payments_rub: payments.rows[0]?.payments_rub ?? 0,
    super_donor_activations: superDonor.rows[0]?.cnt ?? 0,
  };
}

async function fetchBloggersAdmin(db, period = 'all') {
  const partnerWhere = periodSql('u.created_at', period);
  const payWhere = periodSql('pp.created_at', period);

  const result = await db.query(
    `
    SELECT
      u.id,
      u.phone,
      u.name,
      u.partner_public_code,
      (
        SELECT COUNT(*)::int FROM users r
        WHERE r.referred_by_partner_id = u.id
          AND r.referred_at IS NOT NULL
          AND r.referred_at + (365 * INTERVAL '1 day') > NOW()
          AND ${periodSql('r.referred_at', period)}
      ) AS referred_users,
      (
        SELECT COUNT(*)::int FROM partner_payments pp
        WHERE pp.partner_id = u.id AND ${payWhere}
      ) AS payments_count,
      (
        SELECT COALESCE(SUM(pp.amount_rub), 0)::int FROM partner_payments pp
        WHERE pp.partner_id = u.id AND ${payWhere}
      ) AS payments_rub,
      (
        SELECT COALESCE(SUM(pp.partner_commission_rub), 0)::int FROM partner_payments pp
        WHERE pp.partner_id = u.id AND pp.paid_out_at IS NULL
      ) AS payout_pending_rub,
      (
        SELECT COALESCE(SUM(pp.partner_commission_rub), 0)::int FROM partner_payments pp
        WHERE pp.partner_id = u.id AND ${payWhere}
      ) AS bonus_rub
    FROM users u
    WHERE u.is_partner = TRUE
    ORDER BY u.partner_public_code ASC NULLS LAST
    `
  );

  const nextCode = await fetchPartnerCodeStatus(db);

  return {
    next_code: nextCode.next_code,
    bloggers: result.rows,
  };
}

async function fetchListingReportsAdmin(db) {
  const result = await db.query(
    `
    SELECT
      lr.id,
      lr.reason,
      lr.created_at,
      lr.reporter_id,
      ru.name AS reporter_name,
      l.id AS listing_id,
      l.title AS listing_title,
      l.description AS listing_description,
      l.status AS listing_status,
      l.reports_count,
      lu.name AS owner_name,
      lu.phone AS owner_phone,
      lu.id AS owner_id
    FROM listing_reports lr
    JOIN listings l ON l.id = lr.listing_id
    JOIN users ru ON ru.id = lr.reporter_id
    JOIN users lu ON lu.id = l.user_id
    ORDER BY lr.created_at DESC
    LIMIT 100
    `
  );
  return result.rows;
}

async function fetchChatReportsAdmin(db) {
  const result = await db.query(
    `
    SELECT
      cr.id,
      cr.reason,
      cr.status,
      cr.created_at,
      cr.conversation_id,
      cr.reporter_id,
      ru.name AS reporter_name,
      c.listing_id,
      l.title AS listing_title,
      l.status AS listing_status,
      du.name AS donor_name,
      du.phone AS donor_phone,
      du.id AS donor_id,
      rc.name AS recipient_name,
      rc.phone AS recipient_phone,
      rc.id AS recipient_id,
      (
        SELECT json_agg(json_build_object(
          'id', m.id,
          'body', m.body,
          'sender_id', m.sender_id,
          'created_at', m.created_at
        ) ORDER BY m.created_at ASC)
        FROM chat_messages m
        WHERE m.conversation_id = c.id
      ) AS messages
    FROM chat_reports cr
    JOIN conversations c ON c.id = cr.conversation_id
    JOIN listings l ON l.id = c.listing_id
    JOIN users ru ON ru.id = cr.reporter_id
    JOIN users du ON du.id = c.donor_id
    JOIN users rc ON rc.id = c.recipient_id
    WHERE cr.status = 'open'
    ORDER BY cr.created_at DESC
    LIMIT 50
    `
  );
  return result.rows;
}

module.exports = {
  fetchPlatformStats,
  fetchBloggersAdmin,
  fetchListingReportsAdmin,
  fetchChatReportsAdmin,
  markPartnerPayoutComplete,
};
