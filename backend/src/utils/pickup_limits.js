const PICKUP_FREE_LIMIT_START = 7;
const PICKUP_FREE_LIMIT_FULL = 3;
const PLATFORM_ACTIVE_LISTINGS_THRESHOLD = 20000;
const PICKUP_PACK_SIZE = 10;
const PICKUP_PACK_PRICES = [149, 299, 499];
const MAX_PICKUP_PAID_TIERS = PICKUP_PACK_PRICES.length;

function currentMonthKey(date = new Date()) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  return `${year}-${month}`;
}

function getNextPickupPackPrice(tiersBought) {
  if (tiersBought >= MAX_PICKUP_PAID_TIERS) {
    return null;
  }
  return PICKUP_PACK_PRICES[tiersBought];
}

async function countPlatformActiveListings(db) {
  const result = await db.query(
    `
    SELECT COUNT(*)::int AS cnt
    FROM listings
    WHERE status IN ('active', 'reserved')
    `,
  );
  return result.rows[0].cnt;
}

async function getFreePickupLimit(db) {
  const activeListings = await countPlatformActiveListings(db);
  return activeListings >= PLATFORM_ACTIVE_LISTINGS_THRESHOLD
    ? PICKUP_FREE_LIMIT_FULL
    : PICKUP_FREE_LIMIT_START;
}

async function ensurePickupMonth(db, userId) {
  const key = currentMonthKey();
  await db.query(
    `
    UPDATE users
    SET
      pickups_this_month = 0,
      pickup_credits = 0,
      pickup_paid_tiers_bought = 0,
      pickup_month = $2
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

  const freeLimit = await getFreePickupLimit(db);
  const platformActiveListings = await countPlatformActiveListings(db);

  const userResult = await db.query(
    `
    SELECT pickups_this_month, pickup_credits, pickup_paid_tiers_bought
    FROM users
    WHERE id = $1
    `,
    [userId],
  );
  const row = userResult.rows[0];
  const activeReservations = await countActiveReservations(db, userId);
  const usedThisMonth = row.pickups_this_month;
  const credits = row.pickup_credits;
  const tiersBought = row.pickup_paid_tiers_bought;
  const freeRemaining = Math.max(0, freeLimit - usedThisMonth - activeReservations);
  const canReserve = freeRemaining > 0 || credits > 0;
  const blocked = !canReserve && tiersBought >= MAX_PICKUP_PAID_TIERS;
  const nextPackPrice = getNextPickupPackPrice(tiersBought);

  return {
    limit: freeLimit,
    used_this_month: usedThisMonth,
    active_reservations: activeReservations,
    free_remaining: freeRemaining,
    pickup_credits: credits,
    pickup_paid_tiers_bought: tiersBought,
    can_reserve: canReserve,
    blocked,
    next_pack_price: nextPackPrice,
    platform_active_listings: platformActiveListings,
    platform_full_launch: platformActiveListings >= PLATFORM_ACTIVE_LISTINGS_THRESHOLD,
  };
}

function buildPickupLimitResponse(status) {
  const body = {
    code: 'PICKUP_LIMIT',
    limit: status.limit,
    used_this_month: status.used_this_month,
    active_reservations: status.active_reservations,
    free_remaining: status.free_remaining,
    pickup_credits: status.pickup_credits,
    pickup_paid_tiers_bought: status.pickup_paid_tiers_bought,
    blocked: status.blocked,
    platform_full_launch: status.platform_full_launch,
  };

  if (status.blocked) {
    body.message =
      `Лимит заборов на этот месяц исчерпан (${status.limit} бесплатных + все платные пакеты). ` +
      'С нового месяца счётчики обнулятся.';
    return body;
  }

  body.message =
    `Исчерпаны доступные заборы: ${status.used_this_month} из ${status.limit} бесплатных в этом месяце` +
    (status.pickup_credits > 0 ? '' : '.');

  const price = status.next_pack_price;
  if (price != null) {
    const tierNumber = status.pickup_paid_tiers_bought + 1;
    body.upsell = {
      type: 'pickup_pack',
      title: `Пакет заборов ${tierNumber}/${MAX_PICKUP_PAID_TIERS}`,
      price_rub: price,
      extra_pickups: PICKUP_PACK_SIZE,
      tier: tierNumber,
      tiers_total: MAX_PICKUP_PAID_TIERS,
      description:
        `+${PICKUP_PACK_SIZE} заборов за ${price}₽. ` +
        'Лимит получателя не тратится при «Активировать повторно». ' +
        'Каждый месяц — снова с бесплатных заборов.',
    };
  }

  return body;
}

async function consumePickupOnGive(db, userId) {
  await ensurePickupMonth(db, userId);

  const freeLimit = await getFreePickupLimit(db);
  const result = await db.query(
    'SELECT pickups_this_month, pickup_credits FROM users WHERE id = $1',
    [userId],
  );
  const row = result.rows[0];

  if (row.pickups_this_month < freeLimit) {
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
  PICKUP_FREE_LIMIT_START,
  PICKUP_FREE_LIMIT_FULL,
  PLATFORM_ACTIVE_LISTINGS_THRESHOLD,
  PICKUP_PACK_SIZE,
  PICKUP_PACK_PRICES,
  MAX_PICKUP_PAID_TIERS,
  getNextPickupPackPrice,
  getFreePickupLimit,
  getPickupStatus,
  buildPickupLimitResponse,
  consumePickupOnGive,
};
