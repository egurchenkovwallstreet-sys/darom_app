const express = require('express');
const db = require('../db/pool');
const {
  startAdminLogin,
  pollAdminMobileId,
  completeAdminMobileIdPhone,
  confirmAdminMobileIdOtp,
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
const { adminAuthStartLimiter } = require('../middleware/rate_limit');

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
router.post('/auth/start', adminAuthStartLimiter, async (req, res) => {
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

// GET /api/admin/auth/mobile-id/poll?phone=&session_token=
router.get('/auth/mobile-id/poll', async (req, res) => {
  const { phone, session_token: sessionToken } = req.query;
  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и session_token' });
  }

  try {
    const result = await pollAdminMobileId(db, String(phone), String(sessionToken));
    if (!result.ok) {
      return res.status(400).json({ error: result.error });
    }
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/admin/auth/mobile-id/complete { phone, session_token }
router.post('/auth/mobile-id/complete', async (req, res) => {
  const { phone, session_token: sessionToken } = req.body ?? {};
  if (!phone || !sessionToken) {
    return res.status(400).json({ error: 'Нужны phone и session_token' });
  }

  try {
    const result = await completeAdminMobileIdPhone(db, phone, sessionToken);
    if (!result.ok) {
      return res.status(400).json({ error: result.error });
    }
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/admin/auth/mobile-id/confirm { phone, session_token, code }
router.post('/auth/mobile-id/confirm', async (req, res) => {
  const { phone, session_token: sessionToken, code } = req.body ?? {};
  if (!phone || !sessionToken || !code) {
    return res.status(400).json({ error: 'Нужны phone, session_token и code' });
  }

  try {
    const result = await confirmAdminMobileIdOtp(db, phone, sessionToken, code);
    if (!result.ok) {
      return res.status(400).json({ error: result.error });
    }
    res.json(result);
  } catch (error) {
    const message = error.message || 'Ошибка подтверждения';
    if (message.toLowerCase().includes('otp')) {
      return res.status(400).json({ error: 'Неверный код из SMS' });
    }
    res.status(500).json({ error: message });
  }
});

// POST /api/admin/auth/verify { phone, email_code, sms_code? | session_token? }
router.post('/auth/verify', async (req, res) => {
  const {
    phone,
    sms_code: smsCode,
    email_code: emailCode,
    session_token: sessionToken,
  } = req.body ?? {};
  if (!phone || !emailCode) {
    return res.status(400).json({ error: 'Нужны phone и email_code' });
  }

  try {
    const result = await verifyAdminLogin(db, {
      phone,
      smsCode,
      emailCode,
      sessionToken,
    });
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

// POST /api/admin/partner-payout { partner_id } — только super_admin с admin token
router.post('/partner-payout', attachAdmin, requireSuper, async (req, res) => {
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
