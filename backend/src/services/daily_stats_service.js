const PERIOD_LABELS = {
  day: 'Сутки',
  week: 'Неделя',
  month: 'Месяц',
  all: 'Всего',
};

const PERIODS = ['day', 'week', 'month', 'all'];

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

function paidAtFilter(period) {
  if (period === 'all') {
    return "p.status = 'paid' AND p.paid_at IS NOT NULL";
  }
  return `p.status = 'paid' AND ${periodSql('p.paid_at', period)}`;
}

async function fetchPeriodStats(db, period) {
  const userWhere = periodSql('created_at', period);
  const listingsWhere = periodSql('created_at', period);
  const activeWhere = periodSql('last_active_at', period);
  const dealsWhere = periodSql('created_at', period);
  const paidWhere = paidAtFilter(period);
  const partnerSinceWhere =
    period === 'all'
      ? 'u.is_partner = TRUE AND u.partner_since IS NOT NULL'
      : `u.is_partner = TRUE AND ${periodSql('u.partner_since', period)}`;

  const [
    newUsers,
    newListings,
    activeUsers,
    deals,
    payments,
    newBloggers,
    activeBloggers,
  ] = await Promise.all([
    db.query(`SELECT COUNT(*)::int AS cnt FROM users WHERE ${userWhere}`),
    db.query(`SELECT COUNT(*)::int AS cnt FROM listings WHERE ${listingsWhere}`),
    db.query(
      `SELECT COUNT(*)::int AS cnt FROM users WHERE last_active_at IS NOT NULL AND ${activeWhere}`
    ),
    db.query(`SELECT COUNT(*)::int AS cnt FROM deals WHERE ${dealsWhere}`),
    db.query(
      `
      SELECT
        COUNT(*)::int AS payments_count,
        COALESCE(SUM(amount_rub), 0)::int AS payments_rub
      FROM payments p
      WHERE ${paidWhere}
      `
    ),
    db.query(`SELECT COUNT(*)::int AS cnt FROM users u WHERE ${partnerSinceWhere}`),
    db.query(
      `
      SELECT COUNT(*)::int AS cnt FROM (
        SELECT DISTINCT u.id
        FROM users u
        WHERE u.is_partner = TRUE
          AND EXISTS (
            SELECT 1 FROM users r
            WHERE r.referred_by_partner_id = u.id
              AND ${period === 'all' ? 'TRUE' : periodSql('r.referred_at', period)}
          )
          AND EXISTS (
            SELECT 1 FROM partner_payments pp
            WHERE pp.partner_id = u.id
              AND ${period === 'all' ? 'TRUE' : periodSql('pp.created_at', period)}
          )
      ) active_bloggers
      `
    ),
  ]);

  return {
    period,
    label: PERIOD_LABELS[period],
    new_users: newUsers.rows[0]?.cnt ?? 0,
    new_listings: newListings.rows[0]?.cnt ?? 0,
    active_users: activeUsers.rows[0]?.cnt ?? 0,
    deals_count: deals.rows[0]?.cnt ?? 0,
    payments_count: payments.rows[0]?.payments_count ?? 0,
    payments_rub: payments.rows[0]?.payments_rub ?? 0,
    new_bloggers: newBloggers.rows[0]?.cnt ?? 0,
    active_bloggers: activeBloggers.rows[0]?.cnt ?? 0,
  };
}

async function fetchAllDailyStats(db) {
  const stats = {};
  for (const period of PERIODS) {
    stats[period] = await fetchPeriodStats(db, period);
  }
  return stats;
}

function formatStatsBlock(stats) {
  return [
    `▸ ${stats.label}`,
    `  • Новые пользователи: ${stats.new_users}`,
    `  • Новые объявления: ${stats.new_listings}`,
    `  • Активные (заходили): ${stats.active_users}`,
    `  • Сделки: ${stats.deals_count}`,
    `  • Оплаты: ${stats.payments_count} (${stats.payments_rub} ₽)`,
    `  • Новые блогеры: ${stats.new_bloggers}`,
    `  • Активные блогеры: ${stats.active_bloggers}`,
  ].join('\n');
}

function formatReportText(reportDateLabel, statsByPeriod) {
  const blocks = PERIODS.map((period) => formatStatsBlock(statsByPeriod[period]));
  return [
    `Ежедневный отчёт «Даром» — ${reportDateLabel}`,
    '',
    ...blocks,
    '',
    '—',
    'Автоматическое сообщение для главного администратора.',
  ].join('\n');
}

function formatReportHtml(reportDateLabel, statsByPeriod) {
  const blocks = PERIODS.map((period) => {
    const s = statsByPeriod[period];
    return `
      <h3 style="margin:16px 0 8px;color:#00BFFF">${s.label}</h3>
      <ul style="margin:0;padding-left:20px;line-height:1.6">
        <li>Новые пользователи: <strong>${s.new_users}</strong></li>
        <li>Новые объявления: <strong>${s.new_listings}</strong></li>
        <li>Активные (заходили): <strong>${s.active_users}</strong></li>
        <li>Сделки: <strong>${s.deals_count}</strong></li>
        <li>Оплаты: <strong>${s.payments_count}</strong> (${s.payments_rub} ₽)</li>
        <li>Новые блогеры: <strong>${s.new_bloggers}</strong></li>
        <li>Активные блогеры: <strong>${s.active_bloggers}</strong></li>
      </ul>
    `.trim();
  }).join('');

  return `
    <div style="font-family:Arial,sans-serif;color:#001F3F;max-width:640px">
      <h2 style="color:#001F3F">Ежедневный отчёт «Даром»</h2>
      <p style="color:#555">${reportDateLabel}</p>
      ${blocks}
      <p style="margin-top:24px;color:#888;font-size:12px">Автоматическое сообщение для главного администратора.</p>
    </div>
  `.trim();
}

function getMoscowDateParts(date = new Date()) {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Moscow',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: 'numeric',
    minute: 'numeric',
    hour12: false,
  });
  const parts = formatter.formatToParts(date);
  const get = (type) => parts.find((p) => p.type === type)?.value ?? '0';
  return {
    dateKey: `${get('year')}-${get('month')}-${get('day')}`,
    hour: Number(get('hour')),
    minute: Number(get('minute')),
  };
}

function formatReportDateLabel(dateKey) {
  const [year, month, day] = dateKey.split('-');
  return `${day}.${month}.${year}`;
}

module.exports = {
  PERIODS,
  PERIOD_LABELS,
  fetchAllDailyStats,
  formatReportText,
  formatReportHtml,
  formatReportDateLabel,
  getMoscowDateParts,
};
