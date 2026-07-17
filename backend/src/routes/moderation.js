const express = require('express');
const db = require('../db/pool');
const { requireAdminUserSession } = require('../middleware/require_admin_user');
const {
  fetchListingReportsAdmin,
  fetchChatReportsAdmin,
} = require('../utils/admin_stats');
const { blockUser, blockListing } = require('../utils/block_helpers');

const router = express.Router();

// GET /api/moderation/reports/listings
router.get('/reports/listings', ...requireAdminUserSession, async (_req, res) => {
  try {
    const reports = await fetchListingReportsAdmin(db);
    res.json({ reports });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/moderation/reports/chats
router.get('/reports/chats', ...requireAdminUserSession, async (_req, res) => {
  try {
    const reports = await fetchChatReportsAdmin(db);
    res.json({ reports });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/moderation/block/user { user_id, days?, permanent?, reason? }
router.post('/block/user', ...requireAdminUserSession, async (req, res) => {
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
      adminId: req.adminUser.id,
    });
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/moderation/block/listing { listing_id, days?, permanent?, reason? }
router.post('/block/listing', ...requireAdminUserSession, async (req, res) => {
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
      adminId: req.adminUser.id,
    });
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
