const BASE_LISTING_LIMIT = 30;
const SUPER_DONOR_EXTRA = 10;
const SUPER_DONOR_PRICE_RUB = 99;
const SUPER_DONOR_DAYS = 30;

/** @deprecated основатели больше не получают отдельный лимит объявлений */
const FOUNDER_LISTING_LIMIT = BASE_LISTING_LIMIT;

function isSuperDonorActive(user) {
  if (!user?.super_donor_until) return false;
  return new Date(user.super_donor_until) > new Date();
}

function getBaseListingLimit(_user) {
  return BASE_LISTING_LIMIT;
}

function getExtraListingPacks(user) {
  return Number(user?.listing_extra_packs) || 0;
}

function getListingLimit(user) {
  return BASE_LISTING_LIMIT + getExtraListingPacks(user) * SUPER_DONOR_EXTRA;
}

function canOfferSuperDonor(user, activeCount) {
  return activeCount >= getListingLimit(user);
}

function buildListingLimitResponse(user, activeCount) {
  const baseLimit = getBaseListingLimit(user);
  const limit = getListingLimit(user);
  const packs = getExtraListingPacks(user);
  const offerSuper = canOfferSuperDonor(user, activeCount);
  const newLimit = limit + SUPER_DONOR_EXTRA;

  const body = {
    code: 'LISTING_LIMIT',
    message: offerSuper
      ? packs === 0
        ? `У вас ${activeCount} из ${baseLimit} бесплатных объявлений.`
        : `Достигнут лимит: ${activeCount} из ${limit} объявлений.`
      : `Достигнут лимит: ${activeCount} из ${limit} объявлений.`,
    limit,
    base_limit: baseLimit,
    active_count: activeCount,
    extra_packs: packs,
  };

  if (offerSuper) {
    body.upsell = {
      type: 'super_donor',
      title: 'Супер даритель',
      price_rub: SUPER_DONOR_PRICE_RUB,
      duration_days: SUPER_DONOR_DAYS,
      extra_listings: SUPER_DONOR_EXTRA,
      new_limit: newLimit,
      description:
        packs === 0
          ? `+${SUPER_DONOR_EXTRA} объявлений на ${SUPER_DONOR_DAYS} дней, значок и приоритет в ленте`
          : `+${SUPER_DONOR_EXTRA} объявлений за ${SUPER_DONOR_PRICE_RUB}₽ — можно покупать снова без ограничений`,
    };
  }

  return body;
}

module.exports = {
  BASE_LISTING_LIMIT,
  FOUNDER_LISTING_LIMIT,
  SUPER_DONOR_EXTRA,
  SUPER_DONOR_PRICE_RUB,
  SUPER_DONOR_DAYS,
  isSuperDonorActive,
  getBaseListingLimit,
  getExtraListingPacks,
  getListingLimit,
  canOfferSuperDonor,
  buildListingLimitResponse,
};
