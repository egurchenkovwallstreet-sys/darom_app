async function isUserBlocked(db, userId) {
  const result = await db.query(
    `
    SELECT is_blocked_permanent, blocked_until
    FROM users WHERE id = $1
    `,
    [userId]
  );
  const row = result.rows[0];
  if (!row) return false;
  if (row.is_blocked_permanent) return true;
  if (row.blocked_until && new Date(row.blocked_until) > new Date()) return true;
  return false;
}

async function blockUser(db, { userId, days, permanent, reason, adminId }) {
  const blockedUntil = permanent
    ? null
    : new Date(Date.now() + days * 24 * 60 * 60 * 1000);

  await db.query(
    `
    UPDATE users
    SET
      is_blocked_permanent = $2,
      blocked_until = $3
    WHERE id = $1
    `,
    [userId, permanent, blockedUntil]
  );

  await db.query(
    `
    INSERT INTO moderation_actions (admin_id, target_type, target_id, action, days, reason)
    VALUES ($1, 'user', $2, $3, $4, $5)
    `,
    [
      adminId,
      userId,
      permanent ? 'block_perm' : 'block_temp',
      permanent ? null : days,
      reason ?? null,
    ]
  );
}

async function blockListing(db, { listingId, days, permanent, reason, adminId }) {
  const blockedUntil = permanent
    ? null
    : new Date(Date.now() + days * 24 * 60 * 60 * 1000);

  await db.query(
    `
    UPDATE listings
    SET
      status = 'hidden',
      is_blocked_permanent = $2,
      blocked_until = $3
    WHERE id = $1
    `,
    [listingId, permanent, blockedUntil]
  );

  await db.query(
    `
    INSERT INTO moderation_actions (admin_id, target_type, target_id, action, days, reason)
    VALUES ($1, 'listing', $2, $3, $4, $5)
    `,
    [
      adminId,
      listingId,
      permanent ? 'block_perm' : 'block_temp',
      permanent ? null : days,
      reason ?? null,
    ]
  );
}

module.exports = {
  isUserBlocked,
  blockUser,
  blockListing,
};
