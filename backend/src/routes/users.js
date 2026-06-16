const express = require('express');
const multer = require('multer');
const db = require('../db/pool');
const config = require('../config');
const { normalizePhone } = require('../utils/phone');
const { moderatePhoto, resolveMimeType } = require('../utils/photo_moderation');
const { saveAvatar } = require('../utils/photo_storage');
const { normalizeAvatarUrl } = require('../utils/photo_urls');
const {
  getListingLimit,
  getBaseListingLimit,
  isSuperDonorActive,
  SUPER_DONOR_DAYS,
  SUPER_DONOR_EXTRA,
} = require('../utils/limits');
const {
  getPickupStatus,
  PICKUP_PACK_SIZE,
  PICKUP_PACK_PRICE,
} = require('../utils/pickup_limits');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: config.photoMaxBytes },
});

const userFields = `
  id,
  phone,
  name,
  donor_level,
  rating,
  is_founder,
  super_donor_until,
  listing_extra_packs,
  avatar_url,
  is_shadow_banned,
  created_at
`;

const userStatsSubquery = `
  (SELECT COUNT(*)::int FROM listings l WHERE l.user_id = users.id AND l.status IN ('active', 'reserved')) AS active_listings,
  users.items_given,
  users.items_taken
`;

async function formatUserWithStats(db, row) {
  if (!row) return null;

  const pickup = await getPickupStatus(db, row.id);

  return {
    id: row.id,
    phone: row.phone,
    name: row.name,
    donor_level: row.donor_level,
    rating: row.rating,
    is_founder: row.is_founder,
    super_donor_until: row.super_donor_until,
    is_super_donor: isSuperDonorActive(row),
    is_shadow_banned: row.is_shadow_banned ?? false,
    base_listing_limit: getBaseListingLimit(row),
    listing_limit: getListingLimit(row),
    active_listings: row.active_listings ?? 0,
    items_given: row.items_given ?? 0,
    items_taken: row.items_taken ?? 0,
    pickup_limit: pickup.limit,
    pickups_used_this_month: pickup.used_this_month,
    pickups_free_remaining: pickup.free_remaining,
    pickup_credits: pickup.pickup_credits,
    avatar_url: normalizeAvatarUrl(row.avatar_url) || null,
    created_at: row.created_at,
  };
}

async function fetchUserByPhone(normalizedPhone) {
  const result = await db.query(
    `
    SELECT ${userFields},
      ${userStatsSubquery}
    FROM users
    WHERE phone = $1
    `,
    [normalizedPhone]
  );
  return result.rows[0] ?? null;
}

// POST /api/users — регистрация или обновление имени
router.post('/', async (req, res) => {
  const { phone, name } = req.body;

  if (!phone || !name) {
    return res.status(400).json({ error: 'Нужны phone и name' });
  }

  const trimmedName = String(name).trim();
  if (trimmedName.length < 2) {
    return res.status(400).json({ error: 'Имя должно быть не короче 2 символов' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);

    await db.query(
      `
      INSERT INTO users (phone, name, is_founder)
      VALUES ($1, $2, (SELECT COUNT(*) < 1000 FROM users))
      ON CONFLICT (phone) DO UPDATE SET name = EXCLUDED.name
      `,
      [normalizedPhone, trimmedName]
    );

    const user = await fetchUserByPhone(normalizedPhone);
    res.status(201).json({ user: await formatUserWithStats(db, user) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/users?phone=9001234567
router.get('/', async (req, res) => {
  const { phone } = req.query;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен параметр phone' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchUserByPhone(normalizedPhone);

    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    res.json({ user: await formatUserWithStats(db, user) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/users/super-donor — заглушка оплаты до Робокассы (+10 объявлений за покупку)
router.post('/super-donor', async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchUserByPhone(normalizedPhone);

    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    await db.query(
      `
      UPDATE users
      SET
        listing_extra_packs = COALESCE(listing_extra_packs, 0) + 1,
        super_donor_until = GREATEST(COALESCE(super_donor_until, NOW()), NOW()) + ($2 || ' days')::interval
      WHERE phone = $1
      `,
      [normalizedPhone, String(SUPER_DONOR_DAYS)]
    );

    const updated = await fetchUserByPhone(normalizedPhone);
    const newLimit = getListingLimit(updated);
    res.json({
      user: await formatUserWithStats(db, updated),
      message: `+${SUPER_DONOR_EXTRA} объявлений. Теперь до ${newLimit} активных (тестовый режим, без оплаты)`,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/users/pickup-pack — +10 заборов (заглушка до Робокассы)
router.post('/pickup-pack', async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchUserByPhone(normalizedPhone);

    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    await db.query(
      'UPDATE users SET pickup_credits = pickup_credits + $2 WHERE phone = $1',
      [normalizedPhone, PICKUP_PACK_SIZE],
    );

    const updated = await fetchUserByPhone(normalizedPhone);
    res.json({
      user: await formatUserWithStats(db, updated),
      message: `Пакет +${PICKUP_PACK_SIZE} заборов за ${PICKUP_PACK_PRICE}₽ (тестовый режим, без оплаты)`,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/users/avatar — загрузить аватар (multipart: avatar + phone)
router.post('/avatar', upload.single('avatar'), async (req, res) => {
  const phone = req.body?.phone;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }
  if (!req.file) {
    return res.status(400).json({ error: 'Нужен файл avatar' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchUserByPhone(normalizedPhone);

    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
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
    const url = await saveAvatar(req.file.buffer, mimeType, user.id);

    await db.query('UPDATE users SET avatar_url = $2 WHERE id = $1', [user.id, url]);

    const updated = await fetchUserByPhone(normalizedPhone);
    res.json({
      user: await formatUserWithStats(db, updated),
      message: 'Аватар обновлён',
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
