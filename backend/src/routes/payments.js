const express = require('express');
const db = require('../db/pool');
const config = require('../config');
const { normalizePhone } = require('../utils/phone');
const { SUPER_DONOR_PRICE_RUB } = require('../utils/limits');
const {
  getPickupStatus,
  getNextPickupPackPrice,
  MAX_PICKUP_PAID_TIERS,
} = require('../utils/pickup_limits');
const {
  isRobokassaConfigured,
  buildPaymentForm,
  buildPaymentRedirectToken,
  verifyPaymentRedirectToken,
  buildPaymentRedirectHtml,
  verifyResultSignature,
  formatOutSum,
} = require('../utils/robokassa');
const { fulfillPayment } = require('../utils/payment_fulfillment');
const { requireUserSession, rejectMismatchedPhone } = require('../middleware/user_auth');

const router = express.Router();

async function fetchUserByPhone(phone) {
  const result = await db.query('SELECT * FROM users WHERE phone = $1', [phone]);
  return result.rows[0] || null;
}

async function createInvId() {
  const result = await db.query("SELECT nextval('payments_inv_id_seq') AS inv_id");
  return Number(result.rows[0].inv_id);
}

async function resolvePaymentQuote(db, user, productType) {
  if (productType === 'super_donor') {
    return {
      amountRub: SUPER_DONOR_PRICE_RUB,
      tierAtPurchase: null,
      description: 'Super daritel 10 objavlenij',
    };
  }

  if (productType === 'pickup_pack') {
    const status = await getPickupStatus(db, user.id);

    if (status.blocked) {
      throw new Error('Лимит заборов на этот месяц исчерпан. Дождитесь нового месяца.');
    }

    if (status.pickup_paid_tiers_bought >= MAX_PICKUP_PAID_TIERS) {
      throw new Error('Все платные пакеты в этом месяце уже куплены');
    }

    if (status.free_remaining > 0 || status.pickup_credits > 0) {
      throw new Error('Сначала используйте текущие бесплатные заборы и купленный пакет');
    }

    const amountRub = getNextPickupPackPrice(status.pickup_paid_tiers_bought);
    if (amountRub == null) {
      throw new Error('Нет доступного пакета заборов');
    }

    const tierNumber = status.pickup_paid_tiers_bought + 1;
    return {
      amountRub,
      tierAtPurchase: status.pickup_paid_tiers_bought,
      description: `Paket zaborov ${tierNumber} plus 10`,
    };
  }

  throw new Error('Неизвестный product_type. Допустимо: super_donor, pickup_pack');
}

function paymentDescriptionForRow(payment) {
  if (payment.product_type === 'super_donor') {
    return 'Super daritel 10 objavlenij';
  }
  const tierNumber = (payment.tier_at_purchase ?? 0) + 1;
  return `Paket zaborov ${tierNumber} plus 10`;
}

// POST /api/payments/create { phone, product_type }
router.post('/create', requireUserSession, async (req, res) => {
  const { phone, product_type: productType } = req.body;

  if (!phone || !productType) {
    return res.status(400).json({ error: 'Нужны phone и product_type' });
  }
  if (!rejectMismatchedPhone(req, res, phone)) {
    return;
  }

  try {
    const normalizedPhone = normalizePhone(phone);
    const user = await fetchUserByPhone(normalizedPhone);

    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const quote = await resolvePaymentQuote(db, user, productType);
    const useMock = config.paymentMock || !isRobokassaConfigured();

    if (useMock) {
      const invId = await createInvId();
      const insert = await db.query(
        `
        INSERT INTO payments (inv_id, user_id, product_type, amount_rub, tier_at_purchase, status, paid_at)
        VALUES ($1, $2, $3, $4, $5, 'paid', NOW())
        RETURNING *
        `,
        [invId, user.id, productType, quote.amountRub, quote.tierAtPurchase],
      );

      const fulfillment = await fulfillPayment(db, insert.rows[0], user);
      return res.json({
        ok: true,
        mock: true,
        inv_id: invId,
        amount_rub: quote.amountRub,
        message: `${fulfillment.message} (тест без Робокассы)`,
      });
    }

    const invId = await createInvId();
    await db.query(
      `
      INSERT INTO payments (inv_id, user_id, product_type, amount_rub, tier_at_purchase, status)
      VALUES ($1, $2, $3, $4, $5, 'pending')
      `,
      [invId, user.id, productType, quote.amountRub, quote.tierAtPurchase],
    );

    const paymentForm = buildPaymentForm({
      invId,
      amountRub: quote.amountRub,
      description: quote.description,
    });
    const redirectToken = buildPaymentRedirectToken(invId, user.id);
    const paymentUrl =
      `${config.publicBaseUrl}/api/payments/robokassa/go?inv_id=${invId}&token=${redirectToken}`;

    res.json({
      ok: true,
      mock: false,
      inv_id: invId,
      amount_rub: quote.amountRub,
      payment_form: paymentForm,
      payment_url: paymentUrl,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// GET /api/payments/status?inv_id= — проверка после возврата с Робокассы
router.get('/status', requireUserSession, async (req, res) => {
  const invId = Number(req.query.inv_id);
  const phone = req.query.phone;

  if (!invId) {
    return res.status(400).json({ error: 'Нужен inv_id' });
  }
  if (phone && !rejectMismatchedPhone(req, res, phone)) {
    return;
  }

  try {
    const result = await db.query(
      `
      SELECT p.*, u.phone
      FROM payments p
      JOIN users u ON u.id = p.user_id
      WHERE p.inv_id = $1
      `,
      [invId],
    );

    const payment = result.rows[0];
    if (!payment) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }

    if (payment.user_id !== req.userSession.userId) {
      return res.status(403).json({ error: 'Заказ принадлежит другому пользователю' });
    }

    if (phone && normalizePhone(phone) !== payment.phone) {
      return res.status(403).json({ error: 'Заказ принадлежит другому пользователю' });
    }

    res.json({
      ok: true,
      inv_id: payment.inv_id,
      status: payment.status,
      product_type: payment.product_type,
      amount_rub: payment.amount_rub,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/payments/robokassa/go — HTML-форма POST на Robokassa (Receipt не через GET!)
router.get('/robokassa/go', async (req, res) => {
  const invId = Number(req.query.inv_id);
  const token = req.query.token;

  if (!invId || !token) {
    return res.status(400).send('Нужны inv_id и token');
  }

  try {
    const result = await db.query(
      `
      SELECT p.*, u.id AS user_id
      FROM payments p
      JOIN users u ON u.id = p.user_id
      WHERE p.inv_id = $1
      `,
      [invId],
    );

    const payment = result.rows[0];
    if (!payment) {
      return res.status(404).send('Заказ не найден');
    }
    if (payment.status !== 'pending') {
      return res.status(409).send('Заказ уже обработан');
    }
    if (!verifyPaymentRedirectToken(invId, payment.user_id, token)) {
      return res.status(403).send('Неверная ссылка оплаты');
    }

    const paymentForm = buildPaymentForm({
      invId,
      amountRub: payment.amount_rub,
      description: paymentDescriptionForRow(payment),
    });

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(buildPaymentRedirectHtml(paymentForm));
  } catch (error) {
    console.error('Robokassa go error:', error.message);
    res.status(500).send('Ошибка сервера');
  }
});

// POST /api/payments/robokassa/result — Result URL (серверное уведомление)
router.post('/robokassa/result', express.urlencoded({ extended: false }), async (req, res) => {
  try {
    const params = req.body;

    if (!verifyResultSignature(params)) {
      return res.status(400).send('bad sign');
    }

    const invId = Number(params.InvId);
    const outSum = formatOutSum(params.OutSum);

    const claim = await db.query(
      `
      UPDATE payments
      SET status = 'paid', paid_at = NOW()
      WHERE inv_id = $1 AND status = 'pending'
      RETURNING *
      `,
      [invId],
    );

    if (claim.rowCount === 0) {
      const existing = await db.query('SELECT status FROM payments WHERE inv_id = $1', [invId]);
      if (!existing.rows[0]) {
        return res.status(404).send('payment not found');
      }
      if (existing.rows[0].status === 'paid') {
        return res.send(`OK${invId}`);
      }
      return res.status(409).send('not pending');
    }

    const payment = claim.rows[0];

    if (formatOutSum(payment.amount_rub) !== outSum) {
      await db.query(
        `UPDATE payments SET status = 'pending', paid_at = NULL WHERE id = $1`,
        [payment.id],
      );
      return res.status(400).send('bad amount');
    }

    const userResult = await db.query('SELECT * FROM users WHERE id = $1', [payment.user_id]);
    const user = userResult.rows[0];
    if (!user) {
      await db.query(
        `UPDATE payments SET status = 'pending', paid_at = NULL WHERE id = $1`,
        [payment.id],
      );
      return res.status(404).send('user not found');
    }

    try {
      await fulfillPayment(db, payment, user);
    } catch (fulfillError) {
      await db.query(
        `UPDATE payments SET status = 'pending', paid_at = NULL WHERE id = $1`,
        [payment.id],
      );
      throw fulfillError;
    }

    res.send(`OK${invId}`);
  } catch (error) {
    console.error('Robokassa result error:', error.message);
    res.status(500).send('error');
  }
});

// GET /api/payments/robokassa/success — Success URL
router.get('/robokassa/success', (req, res) => {
  const invId = req.query.InvId || req.query.inv_id || '';
  const target = `${config.publicBaseUrl}/payment/success${invId ? `?inv_id=${encodeURIComponent(invId)}` : ''}`;
  res.redirect(target);
});

// GET /api/payments/robokassa/fail — Fail URL
router.get('/robokassa/fail', (req, res) => {
  const invId = req.query.InvId || req.query.inv_id || '';
  const target = `${config.publicBaseUrl}/payment/fail${invId ? `?inv_id=${encodeURIComponent(invId)}` : ''}`;
  res.redirect(target);
});

module.exports = router;
