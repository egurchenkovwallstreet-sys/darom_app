const PICKUP_LIMIT_MONTH = 7;
const PICKUP_PACK_SIZE = 10;
const PICKUP_PACK_PRICE = 99;

function currentMonthKey(date = new Date()) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  return `${year}-${month}`;
}

async function ensurePickupMonth(db, userId) {
  const key = currentMonthKey();
  await db.query(
    `
    UPDATE users
    SET pickups_this_month = 0, pickup_month = $2
    WHERE id = $1 AND (pickup_month IS NULL OR pickup_month <> $2)
    `,
    [userId, key],
  );
}

async function countActiveReservations(db, userId) {
  const result = await db.query(
    `
    SELECT COUNT(*)::int AS cnt
    FROM listings
    WHERE reserved_by_user_id = $1 AND status = 'reserved'
    `,
    [userId],
  );
  return result.rows[0].cnt;
}

async function getPickupStatus(db, userId) {
  await ensurePickupMonth(db, userId);

  const userResult = await db.query(
    'SELECT pickups_this_month, pickup_credits FROM users WHERE id = $1',
    [userId],
  );
  const row = userResult.rows[0];
  const activeReservations = await countActiveReservations(db, userId);
  const usedThisMonth = row.pickups_this_month;
  const credits = row.pickup_credits;
  const freeRemaining = Math.max(0, PICKUP_LIMIT_MONTH - usedThisMonth - activeReservations);
  const canReserve = freeRemaining > 0 || credits > 0;

  return {
    limit: PICKUP_LIMIT_MONTH,
    used_this_month: usedThisMonth,
    active_reservations: activeReservations,
    free_remaining: freeRemaining,
    pickup_credits: credits,
    can_reserve: canReserve,
  };
}

function buildPickupLimitResponse(status) {
  const body = {
    code: 'PICKUP_LIMIT',
    message: `Исчерпан лимит заборов: ${status.used_this_month} из ${status.limit} бесплатных в этом месяце.`,
    limit: status.limit,
    used_this_month: status.used_this_month,
    active_reservations: status.active_reservations,
    free_remaining: status.free_remaining,
    pickup_credits: status.pickup_credits,
  };

  body.upsell = {
    type: 'pickup_pack',
    title: 'Пакет заборов',
    price_rub: PICKUP_PACK_PRICE,
    extra_pickups: PICKUP_PACK_SIZE,
    description: `+${PICKUP_PACK_SIZE} заборов за ${PICKUP_PACK_PRICE}₽. Лимит получателя не тратится при «Активировать повторно».`,
  };

  return body;
}

async function consumePickupOnGive(db, userId) {
  await ensurePickupMonth(db, userId);

  const result = await db.query(
    'SELECT pickups_this_month, pickup_credits FROM users WHERE id = $1',
    [userId],
  );
  const row = result.rows[0];

  if (row.pickups_this_month < PICKUP_LIMIT_MONTH) {
    await db.query(
      'UPDATE users SET pickups_this_month = pickups_this_month + 1 WHERE id = $1',
      [userId],
    );
    return;
  }

  if (row.pickup_credits <= 0) {
    throw new Error('Нет доступных заборов у получателя');
  }

  await db.query(
    'UPDATE users SET pickup_credits = pickup_credits - 1 WHERE id = $1',
    [userId],
  );
}

module.exports = {
  PICKUP_LIMIT_MONTH,
  PICKUP_PACK_SIZE,
  PICKUP_PACK_PRICE,
  getPickupStatus,
  buildPickupLimitResponse,
  consumePickupOnGive,
};
