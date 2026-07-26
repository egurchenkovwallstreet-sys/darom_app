const crypto = require('crypto');
const config = require('../config');
const { digitsForSms } = require('./sms_service');

const API_BASE = 'https://restapi.plusofon.ru/api/v1/flash-call';
const CLIENT_HEADER = '10553';

const FLASH_CALL_HINT =
  'На телефон поступит короткий звонок. Введите последние 4 цифры номера звонящего — отвечать не нужно.';

function isPlusofonConfigured() {
  return Boolean(config.plusofonFlashAccessToken);
}

function canUsePlusofonFlash() {
  if (config.verifyProvider === 'mobile_id') return false;
  if (config.plusofonMock) return true;
  return isPlusofonConfigured();
}

function shouldMockPlusofon() {
  return config.plusofonMock || !isPlusofonConfigured();
}

async function plusofonRequest(path, body) {
  const response = await fetch(`${API_BASE}/${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      Client: CLIENT_HEADER,
      Authorization: `Bearer ${config.plusofonFlashAccessToken}`,
    },
    body: JSON.stringify(body),
  });

  let data;
  try {
    data = await response.json();
  } catch (_) {
    throw new Error('Плюсofon Flash Call: некорректный ответ сервера');
  }

  if (!response.ok || !data.success) {
    const detail = data?.message || JSON.stringify(data);
    throw new Error(`Плюсofon Flash Call: ${detail || 'ошибка запроса'}`);
  }

  return data.data ?? data;
}

async function sendPlusofonFlashCall(phone) {
  const number = digitsForSms(phone);

  if (shouldMockPlusofon()) {
    const pin = String(Math.floor(1000 + Math.random() * 9000));
    const key = crypto.randomUUID();
    console.log(`[Plusofon Flash mock] ${number} → код ${pin}, key ${key}`);
    return { mock: true, key, pin };
  }

  const data = await plusofonRequest('send', { phone: number });
  return {
    mock: false,
    key: String(data.key),
    pin: data.pin ? String(data.pin) : null,
    operator: data.operator ? String(data.operator) : null,
  };
}

async function checkPlusofonFlashPin({ key, pin }) {
  const trimmedPin = String(pin ?? '').trim();
  if (!/^\d{4}$/.test(trimmedPin)) {
    throw new Error('Введите 4 цифры номера входящего звонка');
  }

  if (shouldMockPlusofon()) {
    console.log(`[Plusofon Flash mock check] key=${key} pin=${trimmedPin}`);
    return { ok: true, mock: true };
  }

  await plusofonRequest('check', {
    key: String(key),
    pin: trimmedPin,
  });
  return { ok: true, mock: false };
}

module.exports = {
  FLASH_CALL_HINT,
  isPlusofonConfigured,
  canUsePlusofonFlash,
  sendPlusofonFlashCall,
  checkPlusofonFlashPin,
};
