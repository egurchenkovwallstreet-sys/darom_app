const express = require('express');
const db = require('../db/pool');
const config = require('../config');
const { normalizePhone } = require('../utils/phone');
const {
  fetchPartnerCodeStatus,
  markPartnerPayoutComplete,
  normalizePartnerCode,
} = require('../utils/partner_helpers');

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

// POST /api/admin/partner-payout { admin_secret, phone? , partner_code? }
router.post('/partner-payout', async (req, res) => {
  if (!checkAdminSecret(req, res)) return;

  const { phone, partner_code: partnerCode } = req.body;

  if (!phone && !partnerCode) {
    return res.status(400).json({ error: 'Нужен phone или partner_code партнёра' });
  }

  try {
    let partnerResult;

    if (phone) {
      const normalizedPhone = normalizePhone(phone);
      partnerResult = await db.query(
        `
        SELECT id, name, partner_public_code, phone
        FROM users
        WHERE phone = $1 AND is_partner = TRUE
        `,
        [normalizedPhone]
      );
    } else {
      const code = normalizePartnerCode(partnerCode);
      if (!code) {
        return res.status(400).json({ error: 'Неверный код партнёра' });
      }
      partnerResult = await db.query(
        `
        SELECT id, name, partner_public_code, phone
        FROM users
        WHERE partner_public_code = $1 AND is_partner = TRUE
        `,
        [code]
      );
    }

    const partner = partnerResult.rows[0];
    if (!partner) {
      return res.status(404).json({ error: 'Партнёр не найден' });
    }

    const payout = await markPartnerPayoutComplete(db, partner.id);

    res.json({
      ok: true,
      partner: {
        name: partner.name,
        phone: partner.phone,
        partner_public_code: partner.partner_public_code,
      },
      paid_rub: payout.paid_rub,
      payments_settled: payout.payments_settled,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
