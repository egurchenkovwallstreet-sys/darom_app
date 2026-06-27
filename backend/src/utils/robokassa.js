const crypto = require('crypto');
const config = require('../config');

const ROBOKASSA_PAYMENT_URL = 'https://auth.robokassa.ru/Merchant/Index.aspx';

function md5(value) {
  return crypto.createHash('md5').update(String(value)).digest('hex');
}

function hashSignature(baseString) {
  const algo = (config.robokassa.hashAlgorithm || 'md5').toLowerCase();
  if (algo === 'sha256') {
    return crypto.createHash('sha256').update(String(baseString)).digest('hex');
  }
  return md5(baseString);
}

function isRobokassaConfigured() {
  const { merchantLogin, password1, password2 } = config.robokassa;
  return Boolean(merchantLogin && password1 && password2);
}

function getActivePasswords() {
  if (config.robokassa.testMode) {
    return {
      password1: config.robokassa.testPassword1 || config.robokassa.password1,
      password2: config.robokassa.testPassword2 || config.robokassa.password2,
      isTest: true,
    };
  }
  return {
    password1: config.robokassa.password1,
    password2: config.robokassa.password2,
    isTest: false,
  };
}

function formatOutSum(amountRub) {
  return Number(amountRub).toFixed(2);
}

/**
 * Чек 54-ФЗ — формат как в docs.robokassa.ru/ru/pay-interface (пример Receipt).
 * sum в чеке = OutSum (с копейками).
 */
function buildReceiptPayload(description, outSum) {
  const receipt = {
    items: [
      {
        name: String(description).slice(0, 128),
        quantity: 1,
        sum: Number(outSum),
        tax: config.robokassa.receiptTax || 'none',
      },
    ],
  };
  if (config.robokassa.sno) {
    receipt.sno = config.robokassa.sno;
  }
  return receipt;
}

/** URL-кодированный JSON для подписи и поля Receipt (один раз). */
function encodeReceipt(receiptPayload) {
  const json = JSON.stringify(receiptPayload);
  return encodeURIComponent(json);
}

/**
 * Подпись: MerchantLogin:OutSum:InvId:Receipt:Пароль#1
 * (docs.robokassa.ru/ru/pay-interface — «Только чек»)
 */
function buildPaymentSignature({ merchantLogin, outSum, invId, password1, receiptEncoded }) {
  let base = `${merchantLogin}:${outSum}:${invId}`;
  if (receiptEncoded) {
    base += `:${receiptEncoded}`;
  }
  base += `:${password1}`;
  return hashSignature(base);
}

function buildResultSignature({ outSum, invId, password2, extraParams = {} }) {
  const shpKeys = Object.keys(extraParams)
    .filter((key) => key.startsWith('Shp_'))
    .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

  let base = `${outSum}:${invId}:${password2}`;
  for (const key of shpKeys) {
    base += `:${key}=${extraParams[key]}`;
  }
  return hashSignature(base);
}

/**
 * Поля для POST-формы Robokassa (рекомендуется с Receipt).
 * @returns {{ action: string, method: 'POST', fields: Record<string, string> }}
 */
function buildPaymentForm({ invId, amountRub, description }) {
  const merchantLogin = config.robokassa.merchantLogin;
  const { password1, isTest } = getActivePasswords();
  const outSum = formatOutSum(amountRub);
  const useReceipt = config.robokassa.fiscalReceipt !== false;

  const receiptPayload = useReceipt
    ? buildReceiptPayload(description, outSum)
    : null;
  const receiptEncoded = receiptPayload ? encodeReceipt(receiptPayload) : null;

  const signatureValue = buildPaymentSignature({
    merchantLogin,
    outSum,
    invId,
    password1,
    receiptEncoded,
  });

  const fields = {
    MerchantLogin: merchantLogin,
    OutSum: outSum,
    InvId: String(invId),
    Description: description,
    SignatureValue: signatureValue,
    Culture: 'ru',
    Encoding: 'utf-8',
  };

  if (receiptEncoded) {
    fields.Receipt = receiptEncoded;
  }
  if (isTest) {
    fields.IsTest = '1';
  }

  return {
    action: ROBOKASSA_PAYMENT_URL,
    method: 'POST',
    fields,
  };
}

/** GET-ссылка (запасной вариант; с Receipt лучше POST). */
function buildPaymentUrl(params) {
  const form = buildPaymentForm(params);
  const search = new URLSearchParams(form.fields);
  return `${ROBOKASSA_PAYMENT_URL}?${search.toString()}`;
}

function verifyResultSignature(params) {
  const { password2 } = getActivePasswords();
  const outSum = params.OutSum;
  const invId = params.InvId;
  const signatureValue = String(params.SignatureValue || '').toLowerCase();

  if (!outSum || !invId || !signatureValue) {
    return false;
  }

  const extraParams = {};
  for (const [key, value] of Object.entries(params)) {
    if (key.startsWith('Shp_')) {
      extraParams[key] = value;
    }
  }

  const expected = buildResultSignature({
    outSum,
    invId,
    password2,
    extraParams,
  });

  return expected === signatureValue;
}

function buildPaymentRedirectToken(invId, userId) {
  const secret = config.robokassa.password2 || 'darom-pay-redirect';
  return crypto
    .createHmac('sha256', secret)
    .update(`go:${invId}:${userId}`)
    .digest('hex')
    .slice(0, 32);
}

function verifyPaymentRedirectToken(invId, userId, token) {
  if (!token || String(token).length !== 32) {
    return false;
  }
  const expected = buildPaymentRedirectToken(invId, userId);
  try {
    return crypto.timingSafeEqual(
      Buffer.from(expected, 'utf8'),
      Buffer.from(String(token), 'utf8'),
    );
  } catch {
    return false;
  }
}

function escapeHtmlAttr(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;');
}

function buildPaymentRedirectHtml(form) {
  const inputs = Object.entries(form.fields)
    .map(
      ([name, value]) =>
        `<input type="hidden" name="${escapeHtmlAttr(name)}" value="${escapeHtmlAttr(value)}">`,
    )
    .join('\n');
  const isTest = form.fields.IsTest === '1';

  return `<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Оплата Robokassa</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #001F3F; color: #fff; margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 24px; box-sizing: border-box; }
    .box { max-width: 360px; text-align: center; }
    h1 { font-size: 22px; margin: 0 0 12px; }
    p { opacity: 0.85; line-height: 1.5; margin: 0 0 24px; }
    button { width: 100%; border: 0; border-radius: 25px; padding: 16px 20px; font-size: 17px; font-weight: 600; color: #fff; background: linear-gradient(90deg, #00BFFF, #0077FF); cursor: pointer; }
    .warn { background: rgba(255,87,34,0.2); border: 1px solid #FF5722; border-radius: 12px; padding: 12px; margin-bottom: 20px; font-size: 14px; text-align: left; }
  </style>
</head>
<body>
  <div class="box">
    <h1>Оплата ${escapeHtmlAttr(form.fields.OutSum || '')} ₽</h1>
    ${isTest ? '<div class="warn">⚠ Тестовый режим (IsTest). Для боевой оплаты на сервере нужно ROBOKASSA_TEST_MODE=false</div>' : ''}
    <p>Нажмите кнопку — откроется защищённая страница Robokassa.</p>
    <form id="pay" method="${form.method}" action="${escapeHtmlAttr(form.action)}">
${inputs}
      <button type="submit">Перейти к оплате</button>
    </form>
  </div>
</body>
</html>`;
}

module.exports = {
  ROBOKASSA_PAYMENT_URL,
  isRobokassaConfigured,
  formatOutSum,
  buildReceiptPayload,
  encodeReceipt,
  buildPaymentForm,
  buildPaymentUrl,
  buildPaymentRedirectToken,
  verifyPaymentRedirectToken,
  buildPaymentRedirectHtml,
  verifyResultSignature,
};
