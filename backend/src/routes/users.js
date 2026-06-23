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
  getNextPickupPackPrice,
  MAX_PICKUP_PAID_TIERS,
} = require('../utils/pickup_limits');
const {
  validateActivationCode,
  findPartnerByPublicCode,
  recordPartnerPayment,
  normalizePartnerCode,
} = require('../utils/partner_helpers');
const { checkAdminAccessByPhone } = require('../utils/admin_auth');
const { storeVerifyToken } = require('../utils/phone_verify_token');
const { upsertPushToken } = require('../services/push_service');

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
  is_partner,
  partner_public_code,
  real_phone_verified_at,
  created_at
`;

const userStatsSubquery = `
  (SELECT COUNT(*)::int FROM listings l WHERE l.user_id = users.id AND l.status IN ('active', 'reserved')) AS active_listings,
  users.items_given,
  users.items_taken
`;

async function formatUserWithStats(db, row, { includePhone = false } = {}) {
  if (!row) return null;

  const pickup = await getPickupStatus(db, row.id);

  const user = {
    id: row.id,
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
    pickup_paid_tiers_bought: pickup.pickup_paid_tiers_bought,
    platform_full_launch: pickup.platform_full_launch,
    avatar_url: normalizeAvatarUrl(row.avatar_url) || null,
    is_partner: row.is_partner ?? false,
    partner_public_code: row.partner_public_code ?? null,
    real_phone_verified: Boolean(row.real_phone_verified_at),
    created_at: row.created_at,
  };

  if (includePhone) {
    user.phone = row.phone;
    user.can_access_admin_panel = await checkAdminAccessByPhone(db, row.phone);
  }

  return user;
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
  const {
    phone,
    name,
    partner_activation_code: partnerActivationCode,
    referral_code: referralCode,
  } = req.body;

  if (!phone || !name) {
    return res.status(400).json({ error: 'Нужны phone и name' });
  }

  const trimmedName = String(name).trim();
  if (trimmedName.length < 2) {
    return res.status(400).json({ error: 'Имя должно быть не короче 2 символов' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const existing = await fetchUserByPhone(normalizedPhone);

    if (partnerActivationCode) {
      if (existing) {
        return res.status(400).json({ error: 'Этот номер уже зарегистрирован' });
      }

      const validation = await validateActivationCode(db, partnerActivationCode);
      if (!validation.ok) {
        return res.status(400).json({ error: validation.error });
      }

      const partnerPublicCode = validation.code;

      await db.query('BEGIN');

      const inserted = await db.query(
        `
        INSERT INTO users (
          phone, name, is_founder, phone_verified_at, real_phone_verified_at,
          is_partner, partner_public_code
        )
        VALUES (
          $1, $2, (SELECT COUNT(*) < 1000 FROM users), NOW(), NOW(), TRUE, $3
        )
        RETURNING id
        `,
        [normalizedPhone, trimmedName, partnerPublicCode]
      );

      await db.query(
        `
        UPDATE partner_activation_codes
        SET used_by_user_id = $2, used_at = NOW()
        WHERE code = $1
        `,
        [validation.code, inserted.rows[0].id]
      );

      await db.query('COMMIT');
    } else {
      let referredByPartnerId = null;

      if (referralCode) {
        const partner = await findPartnerByPublicCode(db, referralCode);
        if (!partner) {
          return res.status(400).json({ error: 'Код блогера не найден' });
        }
        referredByPartnerId = partner.id;
      }

      await db.query(
        `
        INSERT INTO users (
          phone, name, is_founder, phone_verified_at, referred_by_partner_id, referred_at
        )
        VALUES (
          $1, $2, (SELECT COUNT(*) < 1000 FROM users), NOW(), $3::uuid,
          CASE WHEN $3::uuid IS NOT NULL THEN NOW() ELSE NULL END
        )
        ON CONFLICT (phone) DO UPDATE SET
          name = EXCLUDED.name,
          phone_verified_at = COALESCE(users.phone_verified_at, NOW()),
          referred_by_partner_id = COALESCE(users.referred_by_partner_id, EXCLUDED.referred_by_partner_id),
          referred_at = COALESCE(
            users.referred_at,
            CASE WHEN EXCLUDED.referred_by_partner_id IS NOT NULL THEN NOW() ELSE NULL END
          )
        `,
        [normalizedPhone, trimmedName, referredByPartnerId]
      );
    }

    const user = await fetchUserByPhone(normalizedPhone);
    const payload = {
      user: await formatUserWithStats(db, user, { includePhone: true }),
    };

    const pinRow = await db.query('SELECT pin_hash FROM users WHERE id = $1', [user.id]);
    if (!pinRow.rows[0]?.pin_hash) {
      const tokenInfo = await storeVerifyToken(normalizedPhone);
      payload.verification_token = tokenInfo.token;
      payload.verification_expires_in = tokenInfo.expires_in;
    }

    res.status(201).json(payload);
  } catch (error) {
    try {
      await db.query('ROLLBACK');
    } catch (_) {}
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

    res.json({ user: await formatUserWithStats(db, user, { includePhone: true }) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/users/super-donor — только при PAYMENT_MOCK=true (иначе /api/payments/create)
router.post('/super-donor', async (req, res) => {
  if (!config.paymentMock) {
    return res.status(400).json({ error: 'Оплата через POST /api/payments/create' });
  }

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

    await recordPartnerPayment(db, user.id, 'super_donor', 99);

    const updated = await fetchUserByPhone(normalizedPhone);
    const newLimit = getListingLimit(updated);
    res.json({
      user: await formatUserWithStats(db, updated, { includePhone: true }),
      message: `+${SUPER_DONOR_EXTRA} объявлений. Теперь до ${newLimit} активных (тестовый режим, без оплаты)`,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/users/pickup-pack — только при PAYMENT_MOCK=true (иначе /api/payments/create)
router.post('/pickup-pack', async (req, res) => {
  if (!config.paymentMock) {
    return res.status(400).json({ error: 'Оплата через POST /api/payments/create' });
  }

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

    const status = await getPickupStatus(db, user.id);

    if (status.blocked) {
      return res.status(400).json({
        error: 'Лимит заборов на этот месяц исчерпан. Дождитесь нового месяца.',
      });
    }

    if (status.pickup_paid_tiers_bought >= MAX_PICKUP_PAID_TIERS) {
      return res.status(400).json({ error: 'Все платные пакеты в этом месяце уже куплены' });
    }

    if (status.free_remaining > 0 || status.pickup_credits > 0) {
      return res.status(400).json({ error: 'Сначала используйте текущие бесплатные заборы и купленный пакет' });
    }

    const price = getNextPickupPackPrice(status.pickup_paid_tiers_bought);
    if (price == null) {
      return res.status(400).json({ error: 'Нет доступного пакета заборов' });
    }

    await db.query(
      `
      UPDATE users
      SET
        pickup_credits = pickup_credits + $2,
        pickup_paid_tiers_bought = pickup_paid_tiers_bought + 1
      WHERE phone = $1
      `,
      [normalizedPhone, PICKUP_PACK_SIZE],
    );

    await recordPartnerPayment(db, user.id, 'pickup_pack', price);

    const updated = await fetchUserByPhone(normalizedPhone);
    res.json({
      user: await formatUserWithStats(db, updated, { includePhone: true }),
      message: `Пакет +${PICKUP_PACK_SIZE} заборов за ${price}₽ (тестовый режим, без оплаты)`,
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

    const moderation = await moderatePhoto(
      req.file.buffer,
      req.file.mimetype,
      req.file.originalname
    );
    if (!moderation.ok) {
      return res.status(400).json({
        error: moderation.error,
        code: moderation.code || 'PHOTO_REJECTED',
      });
    }

    const mimeType =
      moderation.mimeType ||
      resolveMimeType(req.file.buffer, req.file.mimetype, req.file.originalname);
    const url = await saveAvatar(req.file.buffer, mimeType, user.id);

    await db.query('UPDATE users SET avatar_url = $2 WHERE id = $1', [user.id, url]);

    const updated = await fetchUserByPhone(normalizedPhone);
    res.json({
      user: await formatUserWithStats(db, updated, { includePhone: true }),
      message: 'Аватар обновлён',
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/users/push-token { phone, token, platform? }
router.post('/push-token', async (req, res) => {
  const { phone, token, platform } = req.body;

  if (!phone || !token) {
    return res.status(400).json({ error: 'Нужны phone и token' });
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchUserByPhone(normalizedPhone);
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const saved = await upsertPushToken(db, user.id, token, platform || 'web');
    res.json({ ok: true, token_id: saved?.id ?? null });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
