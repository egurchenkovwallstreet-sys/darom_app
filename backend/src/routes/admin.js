const express = require('express');
const db = require('../db/pool');
const {
  startAdminLogin,
  verifyAdminLogin,
  getAdminSession,
  requireAdminRole,
} = require('../utils/admin_auth');
const {
  fetchPlatformStats,
  fetchBloggersAdmin,
  fetchListingReportsAdmin,
  fetchChatReportsAdmin,
  markPartnerPayoutComplete,
} = require('../utils/admin_stats');
const { blockUser, blockListing } = require('../utils/block_helpers');
const config = require('../config');

const router = express.Router();

function getToken(req) {
  const header = req.headers.authorization;
  if (header?.startsWith('Bearer ')) {
    return header.slice(7);
  }
  return req.headers['x-admin-token'] ?? null;
}

async function attachAdmin(req, res, next) {
  const token = getToken(req);
  const session = await getAdminSession(db, token);
  if (!session) {
    return res.status(401).json({ error: 'Нужен вход в админ-панель' });
  }
  req.adminSession = session;
  return next();
}

function requireSuper(req, res, next) {
  if (!requireAdminRole(req.adminSession, ['super_admin'])) {
    return res.status(403).json({ error: 'Доступ только для главного администратора' });
  }
  return next();
}

// POST /api/admin/auth/start { phone }
router.post('/auth/start', async (req, res) => {
  try {
    const result = await startAdminLogin(db, req.body?.phone);
    if (!result.ok) {
      return res.status(403).json({ error: result.error });
    }
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/admin/auth/verify { phone, sms_code, email_code }
router.post('/auth/verify', async (req, res) => {
  const { phone, sms_code: smsCode, email_code: emailCode } = req.body ?? {};
  if (!phone || !smsCode || !emailCode) {
    return res.status(400).json({ error: 'Нужны phone, sms_code и email_code' });
  }

  try {
    const result = await verifyAdminLogin(db, { phone, smsCode, emailCode });
    if (!result.ok) {
      return res.status(400).json({ error: result.error });
    }
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/me
router.get('/me', attachAdmin, async (req, res) => {
  res.json({ admin: req.adminSession });
});

// GET /api/admin/reports/listings
router.get('/reports/listings', attachAdmin, async (req, res) => {
  try {
    const reports = await fetchListingReportsAdmin(db);
    res.json({ reports });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/reports/chats
router.get('/reports/chats', attachAdmin, async (req, res) => {
  try {
    const reports = await fetchChatReportsAdmin(db);
    res.json({ reports });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/admin/block/user { user_id, days?, permanent?, reason? }
router.post('/block/user', attachAdmin, async (req, res) => {
  const { user_id: userId, days, permanent, reason } = req.body ?? {};
  if (!userId) {
    return res.status(400).json({ error: 'Нужен user_id' });
  }

  const isPermanent = Boolean(permanent);
  const blockDays = isPermanent ? null : Math.min(7, Math.max(1, Number(days) || 1));

  if (!isPermanent && (blockDays < 1 || blockDays > 7)) {
    return res.status(400).json({ error: 'Блокировка: от 1 до 7 дней' });
  }

  try {
    await blockUser(db, {
      userId,
      days: blockDays,
      permanent: isPermanent,
      reason,
      adminId: req.adminSession.adminId,
    });
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/admin/block/listing { listing_id, days?, permanent?, reason? }
router.post('/block/listing', attachAdmin, async (req, res) => {
  const { listing_id: listingId, days, permanent, reason } = req.body ?? {};
  if (!listingId) {
    return res.status(400).json({ error: 'Нужен listing_id' });
  }

  const isPermanent = Boolean(permanent);
  const blockDays = isPermanent ? null : Math.min(7, Math.max(1, Number(days) || 1));

  try {
    await blockListing(db, {
      listingId,
      days: blockDays,
      permanent: isPermanent,
      reason,
      adminId: req.adminSession.adminId,
    });
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/stats/platform?period=day|week|month|all
router.get('/stats/platform', attachAdmin, requireSuper, async (req, res) => {
  const period = req.query.period ?? 'all';
  try {
    const stats = await fetchPlatformStats(db, period);
    res.json({ stats });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/stats/bloggers?period=
router.get('/stats/bloggers', attachAdmin, requireSuper, async (req, res) => {
  const period = req.query.period ?? 'all';
  try {
    const data = await fetchBloggersAdmin(db, period);
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/admin/partner-payout { partner_id } или legacy { admin_secret, partner_code }
router.post('/partner-payout', async (req, res) => {
  const secret = req.body?.admin_secret ?? req.headers['x-admin-secret'];
  const isLegacy = secret && config.adminSecret && secret === config.adminSecret;

  if (!isLegacy) {
    return attachAdmin(req, res, () =>
      requireSuper(req, res, async () => {
        const { partner_id: partnerId } = req.body ?? {};
        if (!partnerId) {
          return res.status(400).json({ error: 'Нужен partner_id' });
        }
        try {
          const payout = await markPartnerPayoutComplete(db, partnerId);
          res.json({ ok: true, ...payout });
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      })
    );
  }

  const { partner_id: partnerId, partner_code: partnerCode, phone } = req.body ?? {};
  try {
    let id = partnerId;
    if (!id && partnerCode) {
      const r = await db.query(
        'SELECT id FROM users WHERE partner_public_code = $1 AND is_partner = TRUE',
        [partnerCode]
      );
      id = r.rows[0]?.id;
    }
    if (!id && phone) {
      const { normalizePhone } = require('../utils/phone');
      const r = await db.query(
        'SELECT id FROM users WHERE phone = $1 AND is_partner = TRUE',
        [normalizePhone(phone)]
      );
      id = r.rows[0]?.id;
    }
    if (!id) return res.status(404).json({ error: 'Партнёр не найден' });
    const payout = await markPartnerPayoutComplete(db, id);
    res.json({ ok: true, ...payout });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/partner-codes/status
router.get('/partner-codes/status', attachAdmin, requireSuper, async (_req, res) => {
  try {
    const { fetchPartnerCodeStatus } = require('../utils/partner_helpers');
    const status = await fetchPartnerCodeStatus(db);
    res.json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
