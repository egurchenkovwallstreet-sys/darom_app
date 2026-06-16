const express = require('express');
const db = require('../db/pool');
const { normalizePhone } = require('../utils/phone');
const { getUserByPhone } = require('../db/listing_helpers');
const { recalcUserRating } = require('../utils/ratings');

const router = express.Router();

// POST /api/deals/:id/rate — оценка 1–5 после сделки
router.post('/:id/rate', async (req, res) => {
  const { phone, score } = req.body;
  const { id: dealId } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  const numericScore = Number(score);
  if (!Number.isInteger(numericScore) || numericScore < 1 || numericScore > 5) {
    return res.status(400).json({ error: 'Оценка должна быть от 1 до 5' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const dealResult = await db.query(
      'SELECT id, donor_id, recipient_id FROM deals WHERE id = $1',
      [dealId],
    );
    const deal = dealResult.rows[0];
    if (!deal) {
      return res.status(404).json({ error: 'Сделка не найдена' });
    }

    let toUserId = null;
    if (deal.donor_id === user.id && deal.recipient_id) {
      toUserId = deal.recipient_id;
    } else if (deal.recipient_id === user.id) {
      toUserId = deal.donor_id;
    } else {
      return res.status(403).json({ error: 'Вы не участник этой сделки' });
    }

    await db.query(
      `
      INSERT INTO ratings (deal_id, from_user_id, to_user_id, score)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (deal_id, from_user_id) DO UPDATE SET score = EXCLUDED.score
      `,
      [dealId, user.id, toUserId, numericScore],
    );

    const updated = await recalcUserRating(db, toUserId);

    res.json({
      message: 'Спасибо за оценку!',
      rating: updated.rating,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
