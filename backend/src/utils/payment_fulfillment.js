const { recordPartnerPayment } = require('./partner_helpers');
const {
  SUPER_DONOR_DAYS,
  SUPER_DONOR_EXTRA,
} = require('./limits');
const {
  PICKUP_PACK_SIZE,
  getPickupStatus,
} = require('./pickup_limits');

async function fulfillSuperDonor(db, user) {
  await db.query(
    `
    UPDATE users
    SET
      listing_extra_packs = COALESCE(listing_extra_packs, 0) + 1,
      super_donor_until = GREATEST(COALESCE(super_donor_until, NOW()), NOW()) + ($2 || ' days')::interval
    WHERE id = $1
    `,
    [user.id, String(SUPER_DONOR_DAYS)],
  );

  await recordPartnerPayment(db, user.id, 'super_donor', user.paymentAmountRub);

  return {
    message: `«Супер даритель» активирован: +${SUPER_DONOR_EXTRA} объявлений на ${SUPER_DONOR_DAYS} дней`,
  };
}

async function fulfillPickupPack(db, user, tierAtPurchase) {
  const status = await getPickupStatus(db, user.id);

  if (status.blocked) {
    throw new Error('Лимит заборов на этот месяц исчерпан');
  }

  if (status.pickup_paid_tiers_bought !== tierAtPurchase) {
    throw new Error('Пакет заборов уже куплен или изменился — создайте новый заказ');
  }

  if (status.free_remaining > 0 || status.pickup_credits > 0) {
    throw new Error('Сначала используйте текущие бесплатные заборы и купленный пакет');
  }

  await db.query(
    `
    UPDATE users
    SET
      pickup_credits = pickup_credits + $2,
      pickup_paid_tiers_bought = pickup_paid_tiers_bought + 1
    WHERE id = $1
    `,
    [user.id, PICKUP_PACK_SIZE],
  );

  await recordPartnerPayment(db, user.id, 'pickup_pack', user.paymentAmountRub);

  return {
    message: `Пакет +${PICKUP_PACK_SIZE} заборов за ${user.paymentAmountRub}₽ активирован`,
  };
}

async function fulfillPayment(db, paymentRow, userRow) {
  const user = {
    ...userRow,
    paymentAmountRub: paymentRow.amount_rub,
  };

  if (paymentRow.product_type === 'super_donor') {
    return fulfillSuperDonor(db, user);
  }

  if (paymentRow.product_type === 'pickup_pack') {
    return fulfillPickupPack(db, user, paymentRow.tier_at_purchase);
  }

  throw new Error(`Неизвестный тип оплаты: ${paymentRow.product_type}`);
}

module.exports = {
  fulfillSuperDonor,
  fulfillPickupPack,
  fulfillPayment,
};
