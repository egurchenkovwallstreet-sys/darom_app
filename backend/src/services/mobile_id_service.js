const config = require('../config');
const { digitsForSms } = require('./sms_service');

const STATUS = {
  QUEUE: 0,
  SUCCESS: 1,
  FAILED: 2,
  NEED_OTP: 3,
  IN_PROGRESS: 8,
  ERROR: 16,
};

function isMobileIdConfigured() {
  return Boolean(
    config.smsAeroEmail &&
      config.smsAeroApiKey &&
      config.smsAeroMobileIdSign &&
      config.publicBaseUrl
  );
}

function canUseMobileId() {
  return isMobileIdConfigured() && !config.smsMock && config.smsAuthMode !== 'sms';
}

function mobileIdCallbackUrl() {
  const base = String(config.publicBaseUrl || '').replace(/\/$/, '');
  return `${base}/api/auth/mobile-id/webhook`;
}

async function aeroMobileIdRequest(path, body) {
  const auth = Buffer.from(`${config.smsAeroEmail}:${config.smsAeroApiKey}`).toString('base64');
  const response = await fetch(`https://gate.smsaero.ru/v2/mobile-id/${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  let data;
  try {
    data = await response.json();
  } catch (_) {
    throw new Error('SMS Aero Mobile ID: некорректный ответ');
  }

  if (!response.ok || !data.success) {
    const detail = data?.message || JSON.stringify(data);
    throw new Error(`SMS Aero Mobile ID: ${detail || 'ошибка запроса'}`);
  }

  return data.data;
}

async function sendMobileIdAuth(phone) {
  const number = digitsForSms(phone);
  return aeroMobileIdRequest('send', {
    number,
    sign: config.smsAeroMobileIdSign,
    callbackUrl: mobileIdCallbackUrl(),
  });
}

async function verifyMobileIdOtp({ aeroId, code }) {
  return aeroMobileIdRequest('verify', {
    id: aeroId,
    sign: config.smsAeroMobileIdSign,
    code: String(code).trim(),
  });
}

async function fetchMobileIdStatus(aeroId) {
  return aeroMobileIdRequest('status', { id: aeroId });
}

function isTerminalStatus(status) {
  return [STATUS.SUCCESS, STATUS.FAILED, STATUS.ERROR].includes(Number(status));
}

function statusLabel(status) {
  switch (Number(status)) {
    case STATUS.SUCCESS:
      return 'verified';
    case STATUS.FAILED:
    case STATUS.ERROR:
      return 'failed';
    case STATUS.NEED_OTP:
      return 'need_otp';
    case STATUS.IN_PROGRESS:
      return 'in_progress';
    default:
      return 'pending';
  }
}

module.exports = {
  STATUS,
  isMobileIdConfigured,
  canUseMobileId,
  sendMobileIdAuth,
  verifyMobileIdOtp,
  fetchMobileIdStatus,
  isTerminalStatus,
  statusLabel,
};
