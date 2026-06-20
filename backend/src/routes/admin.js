const express = require('express');
const db = require('../db/pool');
const config = require('../config');
const { fetchPartnerCodeStatus } = require('../utils/partner_helpers');

const router = express.Router();

function checkAdminSecret(req, res) {
  const secret = req.body?.admin_secret ?? req.query?.admin_secret ?? req.headers['x-admin-secret'];
  if (!config.adminSecret || secret !== config.adminSecret) {
    res.status(403).json({ error: 'Нет доступа' });
    return false;
  }
  return true;
}

// GET /api/admin/partner-codes/status?admin_secret=
router.get('/partner-codes/status', async (req, res) => {
  if (!checkAdminSecret(req, res)) return;

  try {
    const status = await fetchPartnerCodeStatus(db);
    res.json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
