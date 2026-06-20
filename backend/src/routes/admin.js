const express = require('express');
const db = require('../db/pool');
const config = require('../config');
const { normalizePartnerCode } = require('../utils/partner_helpers');

const router = express.Router();

function checkAdminSecret(req, res) {
  const secret = req.body?.admin_secret ?? req.headers['x-admin-secret'];
  if (!config.adminSecret || secret !== config.adminSecret) {
    res.status(403).json({ error: 'Нет доступа' });
    return false;
  }
  return true;
}

// POST /api/admin/partner-codes { admin_secret, code, label? }
router.post('/partner-codes', async (req, res) => {
  if (!checkAdminSecret(req, res)) return;

  const { code, label } = req.body;
  const normalized = normalizePartnerCode(code);

  if (!normalized || normalized.length < 4) {
    return res.status(400).json({ error: 'Код партнёра — минимум 4 символа' });
  }

  try {
    await db.query(
      `
      INSERT INTO partner_activation_codes (code, label)
      VALUES ($1, $2)
      ON CONFLICT (code) DO NOTHING
      `,
      [normalized, label ? String(label).trim() : null]
    );

    const row = await db.query(
      'SELECT code, label, used_by_user_id, created_at FROM partner_activation_codes WHERE code = $1',
      [normalized]
    );

    if (!row.rows[0]) {
      return res.status(409).json({ error: 'Такой код уже существует' });
    }

    res.status(201).json({ code: row.rows[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
