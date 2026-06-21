const crypto = require('crypto');
const config = require('../config');

const ROBOKASSA_PAYMENT_URL = 'https://auth.robokassa.ru/Merchant/Index.aspx';

function md5(value) {
  return crypto.createHash('md5').update(String(value)).digest('hex');
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

function buildPaymentSignature({ merchantLogin, outSum, invId, password1 }) {
  return md5(`${merchantLogin}:${outSum}:${invId}:${password1}`);
}

function buildResultSignature({ outSum, invId, password2, extraParams = {} }) {
  const shpKeys = Object.keys(extraParams)
    .filter((key) => key.startsWith('Shp_'))
    .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

  let base = `${outSum}:${invId}:${password2}`;
  for (const key of shpKeys) {
    base += `:${key}=${extraParams[key]}`;
  }
  return md5(base);
}

function buildPaymentUrl({ invId, amountRub, description }) {
  const merchantLogin = config.robokassa.merchantLogin;
  const { password1, isTest } = getActivePasswords();
  const outSum = formatOutSum(amountRub);
  const signatureValue = buildPaymentSignature({
    merchantLogin,
    outSum,
    invId,
    password1,
  });

  const params = new URLSearchParams({
    MerchantLogin: merchantLogin,
    OutSum: outSum,
    InvId: String(invId),
    Description: description,
    SignatureValue: signatureValue,
    Culture: 'ru',
    Encoding: 'utf-8',
  });

  if (isTest) {
    params.set('IsTest', '1');
  }

  return `${ROBOKASSA_PAYMENT_URL}?${params.toString()}`;
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

module.exports = {
  ROBOKASSA_PAYMENT_URL,
  isRobokassaConfigured,
  formatOutSum,
  buildPaymentUrl,
  verifyResultSignature,
};
