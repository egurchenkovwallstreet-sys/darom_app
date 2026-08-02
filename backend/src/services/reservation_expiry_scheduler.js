const { expireReservations } = require('../db/listing_helpers');

const INTERVAL_MS = Number(process.env.RESERVATION_EXPIRY_INTERVAL_MS || 60 * 1000);

function startReservationExpiryScheduler(db) {
  if (process.env.RESERVATION_EXPIRY_DISABLE === 'true') {
    console.log('Reservation expiry scheduler: отключён (RESERVATION_EXPIRY_DISABLE=true)');
    return;
  }

  async function tick() {
    try {
      await expireReservations(db);
    } catch (error) {
      console.error('[RESERVATION EXPIRY] Ошибка:', error.message);
    }
  }

  tick();
  setInterval(tick, INTERVAL_MS);
  console.log(`✓ Reservation expiry scheduler: каждые ${INTERVAL_MS / 1000} с`);
}

module.exports = { startReservationExpiryScheduler };
