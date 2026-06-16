const config = require('../config');
const { normalizePhone } = require('../utils/phone');

function digitsForSms(phone) {
  return normalizePhone(phone).replace(/\D/g, '');
}

function generateCode() {
  return String(Math.floor(1000 + Math.random() * 9000));
}

async function sendSmsCode(phone, code) {
  const apiId = config.smsRuApiId;
  const to = digitsForSms(phone);
  const message = `Даром: код входа ${code}. Никому не сообщайте.`;

  if (config.smsMock || !apiId) {
    console.log(`[SMS mock] ${to} → код ${code}`);
    return { mock: true, debugCode: code };
  }

  const url = new URL('https://sms.ru/sms/send');
  url.searchParams.set('api_id', apiId);
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

  return { mock: false };
}

module.exports = { generateCode, sendSmsCode, digitsForSms };
