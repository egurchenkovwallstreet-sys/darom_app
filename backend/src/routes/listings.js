const express = require('express');
const multer = require('multer');
const db = require('../db/pool');
const config = require('../config');
const {
  expireReservations,
  getUserByPhone,
  fetchListingById,
  mapListingRow,
  photoUrlsField,
} = require('../db/listing_helpers');
const { normalizePhone } = require('../utils/phone');
const { getListingLimit, buildListingLimitResponse } = require('../utils/limits');
const { validateListingText } = require('../utils/stop_words');
const { updateDonorLevel } = require('../utils/donor_level');
const {
  getPickupStatus,
  buildPickupLimitResponse,
  consumePickupOnGive,
} = require('../utils/pickup_limits');
const { moderatePhoto, resolveMimeType } = require('../utils/photo_moderation');
const { savePhoto } = require('../utils/photo_storage');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: config.photoMaxBytes },
});

const listingFields = `
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
  ${photoUrlsField}
`;

async function countActiveListings(userId) {
  const result = await db.query(
    `
    SELECT COUNT(*)::int AS cnt
    FROM listings
    WHERE user_id = $1 AND status IN ('active', 'reserved')
    `,
    [userId]
  );
  return result.rows[0].cnt;
}

// GET /api/listings/mine?phone=9001234567
router.get('/mine', async (req, res) => {
  const { phone } = req.query;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен параметр phone' });
  }

  try {
    await expireReservations(db);
    const normalizedPhone = normalizePhone(phone);

    const result = await db.query(
      `
      SELECT ${listingFields}, 0.0 AS distance_km
      FROM listings l
      JOIN users u ON u.id = l.user_id
      WHERE u.phone = $1
        AND l.status != 'hidden'
      ORDER BY l.created_at DESC
      `,
      [normalizedPhone]
    );

    res.json({ items: result.rows.map(mapListingRow) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/listings/nearby?lat=...&lng=...&radius_km=5
router.get('/nearby', async (req, res) => {
  const lat = Number(req.query.lat ?? 55.7558);
  const lng = Number(req.query.lng ?? 37.6173);
  const radiusKm = Number(req.query.radius_km ?? 5);

  if (!Number.isFinite(lat) || !Number.isFinite(lng) || !Number.isFinite(radiusKm)) {
    return res.status(400).json({ error: 'Некорректные координаты или радиус' });
  }

  const radiusMeters = Math.max(radiusKm, 0.1) * 1000;

  try {
    await expireReservations(db);

    const result = await db.query(
      `
      SELECT
        ${listingFields},
        ROUND(
          (ST_Distance(
            l.location,
            ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography
          ) / 1000.0)::numeric,
          1
        ) AS distance_km,
        ST_Y(l.location::geometry) AS lat,
        ST_X(l.location::geometry) AS lng
      FROM listings l
      JOIN users u ON u.id = l.user_id
      WHERE l.status IN ('active', 'reserved')
        AND u.is_shadow_banned = FALSE
        AND ST_DWithin(
          l.location,
          ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
          $3
        )
      ORDER BY
        CASE WHEN l.status = 'reserved' THEN 1 ELSE 0 END,
        distance_km ASC,
        l.created_at DESC
      LIMIT 200
      `,
      [lat, lng, radiusMeters]
    );

    res.json({ items: result.rows.map(mapListingRow) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/listings/search?q=...&lat=...&lng=...&radius_km=50
router.get('/search', async (req, res) => {
  const q = String(req.query.q || '').trim();
  const lat = Number(req.query.lat ?? 55.7558);
  const lng = Number(req.query.lng ?? 37.6173);
  const radiusKm = Number(req.query.radius_km ?? 50);

  if (q.length < 2) {
    return res.status(400).json({ error: 'Введите минимум 2 символа' });
  }
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || !Number.isFinite(radiusKm)) {
    return res.status(400).json({ error: 'Некорректные координаты или радиус' });
  }

  const radiusMeters = Math.max(radiusKm, 0.1) * 1000;
  const pattern = `%${q}%`;

  try {
    await expireReservations(db);

    const result = await db.query(
      `
      SELECT
        ${listingFields},
        ROUND(
          (ST_Distance(
            l.location,
            ST_SetSRID(ST_MakePoint($3, $2), 4326)::geography
          ) / 1000.0)::numeric,
          1
        ) AS distance_km,
        ST_Y(l.location::geometry) AS lat,
        ST_X(l.location::geometry) AS lng
      FROM listings l
      JOIN users u ON u.id = l.user_id
      WHERE l.status IN ('active', 'reserved')
        AND u.is_shadow_banned = FALSE
        AND (l.title ILIKE $1 OR l.description ILIKE $1)
        AND ST_DWithin(
          l.location,
          ST_SetSRID(ST_MakePoint($3, $2), 4326)::geography,
          $4
        )
      ORDER BY
        CASE WHEN l.status = 'reserved' THEN 1 ELSE 0 END,
        distance_km ASC,
        l.created_at DESC
      LIMIT 100
      `,
      [pattern, lat, lng, radiusMeters]
    );

    res.json({ items: result.rows.map(mapListingRow), query: q });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/listings?category=...&subcategory=...
router.get('/', async (req, res) => {
  const { category, subcategory } = req.query;
  const lat = Number(req.query.lat ?? 55.7558);
  const lng = Number(req.query.lng ?? 37.6173);

  if (!category || !subcategory) {
    return res.status(400).json({
      error: 'Нужны параметры category и subcategory',
    });
  }

  try {
    await expireReservations(db);

    const result = await db.query(
      `
      SELECT
        ${listingFields},
        ROUND(
          (ST_Distance(
            l.location,
            ST_SetSRID(ST_MakePoint($4, $3), 4326)::geography
          ) / 1000.0)::numeric,
          1
        ) AS distance_km
      FROM listings l
      JOIN users u ON u.id = l.user_id
      WHERE l.status IN ('active', 'reserved')
        AND u.is_shadow_banned = FALSE
        AND l.category = $1
        AND l.subcategory = $2
      ORDER BY
        CASE WHEN l.status = 'reserved' THEN 1 ELSE 0 END,
        distance_km ASC,
        l.created_at DESC
      `,
      [category, subcategory, lat, lng]
    );

    res.json({ items: result.rows.map(mapListingRow) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/listings — создать объявление
router.post('/', async (req, res) => {
  const {
    phone,
    title,
    description,
    category,
    subcategory,
    lat = 55.7558,
    lng = 37.6173,
    photos_count = 0,
  } = req.body;

  if (!phone || !title || !description || !category || !subcategory) {
    return res.status(400).json({
      error: 'Нужны phone, title, description, category, subcategory',
    });
  }

  const trimmedTitle = String(title).trim();
  const trimmedDescription = String(description).trim();

  if (trimmedTitle.length < 2) {
    return res.status(400).json({ error: 'Название слишком короткое' });
  }
  if (trimmedDescription.length < 5) {
    return res.status(400).json({ error: 'Описание слишком короткое' });
  }

  const textCheck = validateListingText(trimmedTitle, trimmedDescription);
  if (!textCheck.ok) {
    return res.status(400).json({ error: textCheck.error, code: 'STOP_WORD' });
  }

  try {
    await expireReservations(db);
    const normalizedPhone = normalizePhone(phone);
    const user = await getUserByPhone(db, normalizedPhone);

    if (!user) {
      return res.status(404).json({ error: 'Сначала зарегистрируйтесь в приложении' });
    }

    const activeCount = await countActiveListings(user.id);
    const limit = getListingLimit(user);

    if (activeCount >= limit) {
      return res.status(402).json(buildListingLimitResponse(user, activeCount));
    }

    const insertResult = await db.query(
      `
      INSERT INTO listings (
        user_id, title, description, category, subcategory, photos_count, location
      )
      VALUES (
        $1, $2, $3, $4, $5, $6,
        ST_SetSRID(ST_MakePoint($8, $7), 4326)::geography
      )
      RETURNING id
      `,
      [
        user.id,
        trimmedTitle,
        trimmedDescription,
        category,
        subcategory,
        Number(photos_count) || 0,
        Number(lat),
        Number(lng),
      ]
    );

    const listing = await fetchListingById(db, insertResult.rows[0].id);
    res.status(201).json({ item: mapListingRow(listing) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/listings/:id/photos — загрузить фото (multipart: photo + phone)
router.post('/:id/photos', upload.single('photo'), async (req, res) => {
  const { id } = req.params;
  const phone = req.body?.phone;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }
  if (!req.file) {
    return res.status(400).json({ error: 'Нужен файл photo' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listing = await fetchListingById(db, id);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.owner_id !== user.id) {
      return res.status(403).json({ error: 'Можно добавлять фото только к своим объявлениям' });
    }

    const countResult = await db.query(
      'SELECT COUNT(*)::int AS cnt FROM listing_photos WHERE listing_id = $1',
      [id]
    );
    const currentCount = countResult.rows[0].cnt;
    if (currentCount >= config.photoMaxCount) {
      return res.status(400).json({
        error: `Максимум ${config.photoMaxCount} фото на объявление`,
      });
    }

    const moderation = moderatePhoto(
      req.file.buffer,
      req.file.mimetype,
      req.file.originalname
    );
    if (!moderation.ok) {
      return res.status(400).json({ error: moderation.error, code: 'PHOTO_REJECTED' });
    }

    const mimeType = resolveMimeType(
      req.file.buffer,
      req.file.mimetype,
      req.file.originalname
    );
    const url = await savePhoto(req.file.buffer, mimeType);

    await db.query(
      `
      INSERT INTO listing_photos (listing_id, url, sort_order)
      VALUES ($1, $2, $3)
      `,
      [id, url, currentCount]
    );

    await db.query(
      `
      UPDATE listings
      SET photos_count = (SELECT COUNT(*)::int FROM listing_photos WHERE listing_id = $1)
      WHERE id = $1
      `,
      [id]
    );

    const updated = await fetchListingById(db, id);
    res.status(201).json({ item: mapListingRow(updated) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/listings/:id/reserve — забронировать на 24 ч
router.post('/:id/reserve', async (req, res) => {
  const { phone } = req.body;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    await expireReservations(db);
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listing = await fetchListingById(db, id);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.owner_id === user.id) {
      return res.status(400).json({ error: 'Нельзя забронировать своё объявление' });
    }
    if (listing.status !== 'active') {
      return res.status(400).json({ error: 'Объявление уже забронировано или недоступно' });
    }

    const pickupStatus = await getPickupStatus(db, user.id);
    if (!pickupStatus.can_reserve) {
      return res.status(402).json(buildPickupLimitResponse(pickupStatus));
    }

    await db.query(
      `
      UPDATE listings
      SET
        status = 'reserved',
        reserved_by_user_id = $2,
        reserved_until = NOW() + INTERVAL '24 hours'
      WHERE id = $1 AND status = 'active'
      `,
      [id, user.id]
    );

    const updated = await fetchListingById(db, id);
    res.json({ item: mapListingRow(updated) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/listings/:id/give — даритель отдал вещь
router.post('/:id/give', async (req, res) => {
  const { phone } = req.body;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    await expireReservations(db);
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listing = await fetchListingById(db, id);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.owner_id !== user.id) {
      return res.status(403).json({ error: 'Только даритель может отметить «Отдал»' });
    }
    if (listing.status !== 'reserved') {
      return res.status(400).json({ error: 'Сначала нужно бронирование получателя' });
    }

    const recipientId = listing.reserved_by_user_id;

    const dealResult = await db.query(
      `
      INSERT INTO deals (listing_id, donor_id, recipient_id)
      VALUES ($1, $2, $3)
      RETURNING id
      `,
      [id, user.id, recipientId],
    );
    const dealId = dealResult.rows[0].id;

    await db.query(
      `
      UPDATE listings
      SET
        status = 'given',
        reserved_by_user_id = NULL,
        reserved_until = NULL
      WHERE id = $1
      `,
      [id]
    );

    await db.query(
      'UPDATE users SET items_given = items_given + 1 WHERE id = $1',
      [user.id]
    );

    if (recipientId) {
      await consumePickupOnGive(db, recipientId);
      await db.query(
        'UPDATE users SET items_taken = items_taken + 1 WHERE id = $1',
        [recipientId]
      );
    }

    await updateDonorLevel(db, user.id);

    let counterpartyName = null;
    if (recipientId) {
      const nameResult = await db.query('SELECT name FROM users WHERE id = $1', [recipientId]);
      counterpartyName = nameResult.rows[0]?.name ?? null;
    }

    const updated = await fetchListingById(db, id);
    res.json({
      item: mapListingRow(updated),
      deal: recipientId
        ? {
            id: dealId,
            counterparty_name: counterpartyName,
            counterparty_role: 'recipient',
          }
        : null,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/listings/:id/reactivate — снова активно (лимит получателя не тратится)
router.post('/:id/reactivate', async (req, res) => {
  const { phone } = req.body;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listing = await fetchListingById(db, id);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.owner_id !== user.id) {
      return res.status(403).json({ error: 'Только даритель может активировать повторно' });
    }
    if (listing.status !== 'reserved') {
      return res.status(400).json({ error: 'Можно активировать только забронированное объявление' });
    }

    const activeCount = await countActiveListings(user.id);
    const limit = getListingLimit(user);
    if (activeCount >= limit) {
      return res.status(402).json(buildListingLimitResponse(user, activeCount));
    }

    await db.query(
      `
      UPDATE listings
      SET
        status = 'active',
        reserved_by_user_id = NULL,
        reserved_until = NULL
      WHERE id = $1
      `,
      [id]
    );

    const updated = await fetchListingById(db, id);
    res.json({ item: mapListingRow(updated) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PATCH /api/listings/:id — редактировать своё объявление
router.patch('/:id', async (req, res) => {
  const { phone, title, description, category, subcategory } = req.body;
  const { id } = req.params;

  if (!phone || !title || !description || !category || !subcategory) {
    return res.status(400).json({
      error: 'Нужны phone, title, description, category, subcategory',
    });
  }

  const trimmedTitle = String(title).trim();
  const trimmedDescription = String(description).trim();

  if (trimmedTitle.length < 2) {
    return res.status(400).json({ error: 'Название слишком короткое' });
  }
  if (trimmedDescription.length < 5) {
    return res.status(400).json({ error: 'Описание слишком короткое' });
  }

  const textCheck = validateListingText(trimmedTitle, trimmedDescription);
  if (!textCheck.ok) {
    return res.status(400).json({ error: textCheck.error, code: 'STOP_WORD' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listing = await fetchListingById(db, id);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.owner_id !== user.id) {
      return res.status(403).json({ error: 'Можно редактировать только свои объявления' });
    }
    if (listing.status === 'given' || listing.status === 'hidden') {
      return res.status(400).json({ error: 'Это объявление нельзя редактировать' });
    }

    await db.query(
      `
      UPDATE listings
      SET title = $2, description = $3, category = $4, subcategory = $5
      WHERE id = $1
      `,
      [id, trimmedTitle, trimmedDescription, category, subcategory]
    );

    const updated = await fetchListingById(db, id);
    res.json({ item: mapListingRow(updated) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/listings/:id/delete — удалить своё объявление (скрыть)
router.post('/:id/delete', async (req, res) => {
  const { phone } = req.body;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listing = await fetchListingById(db, id);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.owner_id !== user.id) {
      return res.status(403).json({ error: 'Можно удалять только свои объявления' });
    }
    if (listing.status === 'given') {
      return res.status(400).json({ error: 'Отданное объявление удалить нельзя' });
    }
    if (listing.status === 'hidden') {
      return res.status(400).json({ error: 'Объявление уже удалено' });
    }

    await db.query(
      `
      UPDATE listings
      SET
        status = 'hidden',
        reserved_by_user_id = NULL,
        reserved_until = NULL
      WHERE id = $1
      `,
      [id]
    );

    res.json({ ok: true, message: 'Объявление удалено' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/listings/:id/report — жалоба (3 → скрытие)
router.post('/:id/report', async (req, res) => {
  const { phone, reason } = req.body;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listing = await fetchListingById(db, id);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.owner_id === user.id) {
      return res.status(400).json({ error: 'Нельзя пожаловаться на своё объявление' });
    }
    if (listing.status === 'hidden') {
      return res.status(400).json({ error: 'Объявление уже скрыто' });
    }

    const insertResult = await db.query(
      `
      INSERT INTO listing_reports (listing_id, reporter_id, reason)
      VALUES ($1, $2, $3)
      ON CONFLICT (listing_id, reporter_id) DO NOTHING
      RETURNING id
      `,
      [id, user.id, reason ? String(reason).trim().slice(0, 500) : null],
    );

    if (insertResult.rowCount === 0) {
      return res.status(400).json({ error: 'Вы уже отправляли жалобу на это объявление' });
    }

    const countResult = await db.query(
      `
      UPDATE listings
      SET reports_count = reports_count + 1
      WHERE id = $1
      RETURNING reports_count, status
      `,
      [id],
    );

    let reportsCount = countResult.rows[0].reports_count;
    let hidden = false;

    if (reportsCount >= 3) {
      await db.query(`UPDATE listings SET status = 'hidden' WHERE id = $1`, [id]);
      hidden = true;
    }

    res.json({
      message: hidden
        ? 'Объявление скрыто после 3 жалоб'
        : 'Жалоба принята. Спасибо!',
      reports_count: reportsCount,
      hidden,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
