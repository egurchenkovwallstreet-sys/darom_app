const express = require('express');
const db = require('../db/pool');
const { requireSuperAdminUserSession } = require('../middleware/require_admin_user');
const { generateDailyReport } = require('../services/daily_report_scheduler');

const router = express.Router();

function mapReportRow(row) {
  return {
    id: row.id,
    report_date: row.report_date,
    title: row.title,
    body_text: row.body_text,
    body_html: row.body_html,
    stats: typeof row.stats_json === 'string' ? JSON.parse(row.stats_json) : row.stats_json,
    email_sent_at: row.email_sent_at,
    created_at: row.created_at,
  };
}

// GET /api/daily-reports
router.get('/', ...requireSuperAdminUserSession, async (_req, res) => {
  try {
    const result = await db.query(
      `
      SELECT id, report_date, title, body_text, stats_json, email_sent_at, created_at
      FROM admin_daily_reports
      ORDER BY report_date DESC
      LIMIT 60
      `
    );
    res.json({
      items: result.rows.map((row) => ({
        id: row.id,
        report_date: row.report_date,
        title: row.title,
        preview: String(row.body_text ?? '').split('\n').slice(0, 3).join('\n'),
        email_sent_at: row.email_sent_at,
        created_at: row.created_at,
      })),
    });
  } catch (error) {
    const message = String(error?.message ?? error);
    if (error?.code === '42P01') {
      return res.status(503).json({
        error: 'База не обновлена: выполните migrate_admin_daily_reports.sql на сервере (VNC)',
      });
    }
    res.status(500).json({ error: message });
  }
});

// GET /api/daily-reports/:id
router.get('/:id', ...requireSuperAdminUserSession, async (req, res) => {
  try {
    const result = await db.query(
      `
      SELECT id, report_date, title, body_text, body_html, stats_json, email_sent_at, created_at
      FROM admin_daily_reports
      WHERE id = $1
      `,
      [req.params.id]
    );
    const row = result.rows[0];
    if (!row) {
      return res.status(404).json({ error: 'Отчёт не найден' });
    }
    res.json({ report: mapReportRow(row) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/daily-reports/generate — ручной запуск (тест)
router.post('/generate', ...requireSuperAdminUserSession, async (req, res) => {
  try {
    const force = Boolean(req.body?.force);
    const result = await generateDailyReport(db, { force });
    if (result.skipped && !force) {
      return res.json({ ok: true, skipped: true, reason: result.reason });
    }
    res.json({ ok: true, report: mapReportRow(result.report) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
