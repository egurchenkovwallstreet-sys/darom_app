const express = require('express');
const db = require('../db/pool');
const { normalizePhone } = require('../utils/phone');
const {
  validateActivationCode,
  fetchPartnerStats,
  normalizePartnerCode,
  getNextAvailableActivationCode,
} = require('../utils/partner_helpers');

const router = express.Router();

// POST /api/partners/validate-activation-code { code }
router.post('/validate-activation-code', async (req, res) => {
  const { code } = req.body;

  if (!code) {
    return res.status(400).json({ error: 'Нужен код партнёра' });
  }

  try {
    const validation = await validateActivationCode(db, code);
    if (!validation.ok) {
      return res.status(400).json({ error: validation.error });
    }

    res.json({
      ok: true,
      code: validation.code,
      label: validation.label ?? null,
      sequence_num: validation.sequence_num ?? null,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/partners/next-code — какой код сейчас активен (для администратора в приложении)
router.get('/next-code', async (_req, res) => {
  try {
    const next = await getNextAvailableActivationCode(db);
    if (!next) {
      return res.json({ code: null, message: 'Все 1000 кодов использованы' });
    }
    res.json({ code: next.code, sequence_num: next.sequence_num });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/partners/stats?phone=
router.get('/stats', async (req, res) => {
  const { phone } = req.query;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен параметр phone' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const userResult = await db.query(
      `
      SELECT id, is_partner, partner_public_code, name
      FROM users
      WHERE phone = $1
      `,
      [normalizedPhone]
    );
    const user = userResult.rows[0];

    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    if (!user.is_partner) {
      return res.status(403).json({ error: 'Доступно только партнёрам' });
    }

    const stats = await fetchPartnerStats(db, user.id);

    res.json({
      partner: {
        name: user.name,
        partner_public_code: user.partner_public_code,
      },
      stats,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
