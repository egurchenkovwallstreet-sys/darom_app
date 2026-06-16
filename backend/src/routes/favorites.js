const express = require('express');
const db = require('../db/pool');
const { normalizePhone } = require('../utils/phone');
const { getUserByPhone, mapListingRow, photoUrlsField } = require('../db/listing_helpers');

const router = express.Router();

async function fetchFavoriteListings(userId) {
  const result = await db.query(
    `
    SELECT
      l.id,
      l.user_id AS owner_id,
      l.title,
      l.description,
      l.category,
      l.subcategory,
      l.photos_count,
      l.status,
      l.reserved_until,
      u.name AS author_name,
      u.donor_level AS author_level,
      u.rating AS author_rating,
      ST_Y(l.location::geometry) AS lat,
      ST_X(l.location::geometry) AS lng,
      ${photoUrlsField}
    FROM favorites f
    JOIN listings l ON l.id = f.listing_id
    JOIN users u ON u.id = l.user_id
    WHERE f.user_id = $1
      AND l.status IN ('active', 'reserved')
    ORDER BY f.created_at DESC
    `,
    [userId]
  );

  return result.rows.map((row) => ({
    ...mapListingRow(row),
    distance_km: 0,
  }));
}

// GET /api/favorites?phone=
router.get('/', async (req, res) => {
  const { phone } = req.query;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен параметр phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const items = await fetchFavoriteListings(user.id);
    const idsResult = await db.query(
      'SELECT listing_id FROM favorites WHERE user_id = $1',
      [user.id]
    );

    res.json({
      items,
      ids: idsResult.rows.map((row) => row.listing_id),
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/favorites/ids?phone=
router.get('/ids', async (req, res) => {
  const { phone } = req.query;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен параметр phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const result = await db.query(
      'SELECT listing_id FROM favorites WHERE user_id = $1',
      [user.id]
    );

    res.json({ ids: result.rows.map((row) => row.listing_id) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/favorites/:listingId
router.post('/:listingId', async (req, res) => {
  const { phone } = req.body;
  const { listingId } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listingResult = await db.query(
      'SELECT id, status FROM listings WHERE id = $1',
      [listingId]
    );
    const listing = listingResult.rows[0];
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (!['active', 'reserved'].includes(listing.status)) {
      return res.status(400).json({ error: 'Объявление недоступно для избранного' });
    }

    await db.query(
      `
      INSERT INTO favorites (user_id, listing_id)
      VALUES ($1, $2)
      ON CONFLICT (user_id, listing_id) DO NOTHING
      `,
      [user.id, listingId]
    );

    res.status(201).json({ message: 'Добавлено в избранное', listing_id: listingId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// DELETE /api/favorites/:listingId?phone=
router.delete('/:listingId', async (req, res) => {
  const phone = req.body?.phone || req.query.phone;
  const { listingId } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    await db.query(
      'DELETE FROM favorites WHERE user_id = $1 AND listing_id = $2',
      [user.id, listingId]
    );

    res.json({ message: 'Удалено из избранного', listing_id: listingId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
