const config = require('../config');
const { normalizePhone } = require('../utils/phone');

function digitsForSms(phone) {
  return normalizePhone(phone).replace(/\D/g, '');
}

function generateCode() {
  return String(Math.floor(1000 + Math.random() * 9000));
}

function isSmsAeroConfigured() {
  return Boolean(config.smsAeroEmail && config.smsAeroApiKey);
}

function isSmsRuConfigured() {
  return Boolean(config.smsRuApiId);
}

function resolveProvider() {
  const preferred = String(config.smsProvider || 'smsaero').toLowerCase();
  if (preferred === 'smsru' && isSmsRuConfigured()) return 'smsru';
  if (preferred === 'smsaero' && isSmsAeroConfigured()) return 'smsaero';
  if (isSmsAeroConfigured()) return 'smsaero';
  if (isSmsRuConfigured()) return 'smsru';
  return null;
}

function canSendRealSms() {
  return Boolean(resolveProvider()) && !config.smsMock;
}

/**
 * mode:
 * - mock — всегда тест (регистрация, админка)
 * - real — боевое SMS через SMS Aero или SMS.ru
 * - default — как SMS_MOCK в .env
 */
async function sendSmsCode(phone, code, options = {}) {
  const mode = options.mode || 'default';
  const to = digitsForSms(phone);
  const message = `Даром: код входа ${code}. Никому не сообщайте.`;

  const useMock =
    mode === 'mock' ||
    (mode === 'default' && config.smsMock) ||
    (mode === 'real' && !canSendRealSms());

  if (useMock) {
    let reason = '';
    if (mode === 'real') {
      reason = config.smsMock
        ? 'SMS_MOCK=true'
        : 'нет SMS_AERO_EMAIL/SMS_AERO_API_KEY в backend/.env';
    }
    const suffix = reason ? ` (${reason})` : '';
    console.log(`[SMS mock${suffix}] ${to} → код ${code}`);
    return { mock: true, debugCode: code };
  }

  const provider = resolveProvider();
  if (provider === 'smsaero') {
    await sendViaSmsAero(to, message);
    return { mock: false, provider: 'smsaero' };
  }

  await sendViaSmsRu(to, message);
  return { mock: false, provider: 'smsru' };
}

async function sendViaSmsAero(to, message) {
  const auth = Buffer.from(`${config.smsAeroEmail}:${config.smsAeroApiKey}`).toString('base64');
  const url = new URL('https://gate.smsaero.ru/v2/sms/send');
  url.searchParams.set('number', to);
  url.searchParams.set('text', message);
  url.searchParams.set('sign', config.smsAeroSign);

  const response = await fetch(url.toString(), {
    headers: { Authorization: `Basic ${auth}` },
  });

  let data;
  try {
    data = await response.json();
  } catch (_) {
    throw new Error('SMS Aero: некорректный ответ сервера');
  }

  if (!response.ok || !data.success) {
    const detail = data?.message || data?.data?.message || JSON.stringify(data);
    throw new Error(`SMS Aero: ${detail || 'не отправил сообщение'}`);
  }
}

async function sendViaSmsRu(to, message) {
  const url = new URL('https://sms.ru/sms/send');
  url.searchParams.set('api_id', config.smsRuApiId);
  url.searchParams.set('to', to);
  url.searchParams.set('msg', message);
  url.searchParams.set('json', '1');

  const response = await fetch(url.toString());
  const data = await response.json();

  if (data.status !== 'OK') {
    throw new Error(data.status_text || 'SMS.ru не отправил сообщение');
  }

  const smsStatus = data.sms?.[to];
  if (smsStatus && smsStatus.status !== 'OK') {
    throw new Error(smsStatus.status_text || 'Ошибка доставки SMS');
  }
}

module.exports = {
  generateCode,
  sendSmsCode,
  digitsForSms,
  canSendRealSms,
  resolveProvider,
};
