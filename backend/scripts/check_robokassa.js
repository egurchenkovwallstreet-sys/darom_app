/**
 * Проверка настроек Robokassa на сервере (без секретов в выводе).
 * node scripts/check_robokassa.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const config = require('../src/config');
const {
  buildPaymentForm,
  buildReceiptPayload,
  encodeReceipt,
} = require('../src/utils/robokassa');

const rawTestMode = process.env.ROBOKASSA_TEST_MODE;
const login = config.robokassa.merchantLogin;
const form = buildPaymentForm({
  invId: 19999,
  amountRub: 99,
  description: 'Super daritel 10 objavlenij',
});
const receiptPayload = buildReceiptPayload('Super daritel 10 objavlenij', '99.00');
const receiptEncoded = encodeReceipt(receiptPayload);

console.log('--- Robokassa diagnostic ---');
console.log('ROBOKASSA_TEST_MODE в .env:', rawTestMode === undefined ? '(нет строки)' : JSON.stringify(rawTestMode));
console.log('testMode в backend:', config.robokassa.testMode, config.robokassa.testMode ? '(IsTest=1!)' : '(боевой)');
console.log('ROBOKASSA_MERCHANT_LOGIN:', login || '(пусто!)');
console.log('Пароль #1 задан:', Boolean(config.robokassa.password1));
console.log('Пароль #2 задан:', Boolean(config.robokassa.password2));
console.log('PAYMENT_MOCK:', config.paymentMock);
console.log('fiscalReceipt:', config.robokassa.fiscalReceipt);
console.log('IsTest в форме:', form.fields.IsTest === '1' ? 'ДА' : 'нет');
console.log('Receipt в форме:', form.fields.Receipt ? 'ДА' : 'нет');
console.log('Email в форме:', form.fields.Email || '(не задан — добавьте ROBOKASSA_PAYMENT_EMAIL в .env)');
console.log('OutSum:', form.fields.OutSum);
console.log('Receipt JSON:', JSON.stringify(receiptPayload));
console.log('Receipt encoded (первые 80 символов):', receiptEncoded.slice(0, 80) + '...');
console.log('Подпись (без пароля):', `${login}:${form.fields.OutSum}:${form.fields.InvId}:${receiptEncoded}:***`);
console.log('SignatureValue:', form.fields.SignatureValue);
console.log('Метод оплаты: POST на', form.action);
console.log('Поля формы:', Object.keys(form.fields).join(', '));
