const config = require('../config');
const {
  fetchAllDailyStats,
  formatReportText,
  formatReportHtml,
  formatReportDateLabel,
  getMoscowDateParts,
} = require('./daily_stats_service');
const { sendAdminDailyReportEmail } = require('./email_service');

async function reportExistsForDate(db, dateKey) {
  const result = await db.query(
    'SELECT id FROM admin_daily_reports WHERE report_date = $1::date LIMIT 1',
    [dateKey]
  );
  return Boolean(result.rows[0]);
}

async function generateDailyReport(db, { dateKey = null, force = false } = {}) {
  const moscow = getMoscowDateParts();
  const reportDate = dateKey ?? moscow.dateKey;

  if (!force && (await reportExistsForDate(db, reportDate))) {
    return { skipped: true, reason: 'already_exists', report_date: reportDate };
  }

  const stats = await fetchAllDailyStats(db);
  const dateLabel = formatReportDateLabel(reportDate);
  const title = `Статистика «Даром» — ${dateLabel}`;
  const bodyText = formatReportText(dateLabel, stats);
  const bodyHtml = formatReportHtml(dateLabel, stats);

  const result = await db.query(
    `
    INSERT INTO admin_daily_reports (report_date, title, body_text, body_html, stats_json)
    VALUES ($1::date, $2, $3, $4, $5::jsonb)
    ON CONFLICT (report_date) DO UPDATE SET
      title = EXCLUDED.title,
      body_text = EXCLUDED.body_text,
      body_html = EXCLUDED.body_html,
      stats_json = EXCLUDED.stats_json
    RETURNING id, report_date, title, body_text, body_html, stats_json, email_sent_at, created_at
    `,
    [reportDate, title, bodyText, bodyHtml, JSON.stringify(stats)]
  );

  const report = result.rows[0];
  let emailResult = null;

  if (!report.email_sent_at || force) {
    emailResult = await sendAdminDailyReportEmail({
      to: config.adminEmail,
      subject: title,
      text: bodyText,
      html: bodyHtml,
    });

    if (emailResult.sent || emailResult.mock) {
      await db.query(
        'UPDATE admin_daily_reports SET email_sent_at = NOW() WHERE id = $1',
        [report.id]
      );
      report.email_sent_at = new Date().toISOString();
    }
  }

  return {
    skipped: false,
    report,
    email: emailResult,
  };
}

function startDailyReportScheduler(db) {
  if (process.env.DAILY_REPORT_DISABLE === 'true') {
    console.log('Daily report scheduler: отключён (DAILY_REPORT_DISABLE=true)');
    return;
  }

  const targetHour = Number(process.env.DAILY_REPORT_HOUR_MSK || 21);

  async function tick() {
    try {
      const moscow = getMoscowDateParts();
      if (moscow.hour !== targetHour) return;

      const exists = await reportExistsForDate(db, moscow.dateKey);
      if (exists) return;

      console.log(`[DAILY REPORT] Генерация отчёта за ${moscow.dateKey} (21:00 МСК)…`);
      const result = await generateDailyReport(db, { dateKey: moscow.dateKey });
      if (result.skipped) {
        console.log(`[DAILY REPORT] Пропуск: ${result.reason}`);
      } else {
        console.log(`[DAILY REPORT] Отчёт создан: ${result.report.id}`);
      }
    } catch (error) {
      console.error('[DAILY REPORT] Ошибка:', error.message);
    }
  }

  tick();
  setInterval(tick, 60 * 1000);
  console.log(`✓ Daily report scheduler: каждый день в ${targetHour}:00 МСК`);
}

module.exports = {
  generateDailyReport,
  reportExistsForDate,
  startDailyReportScheduler,
};
