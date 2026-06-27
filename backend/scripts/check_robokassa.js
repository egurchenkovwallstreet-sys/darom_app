/**
 * Проверка настроек Рobokassa на сервере (без секретов в выводе).
 * node scripts/check_robokassa.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const config = require('../src/config');
const { buildPaymentUrl } = require('../src/utils/robokassa');

const rawTestMode = process.env.ROBOKASSA_TEST_MODE;
const login = config.robokassa.merchantLogin;
const url = buildPaymentUrl({
  invId: 19999,
  amountRub: 99,
  description: 'Darom check',
});

console.log('--- Robokassa diagnostic ---');
console.log('ROBOKASSA_TEST_MODE в .env:', rawTestMode === undefined ? '(нет строки)' : JSON.stringify(rawTestMode));
console.log('testMode в backend:', config.robokassa.testMode, config.robokassa.testMode ? '(IsTest=1 в ссылке!)' : '(боевой, без IsTest)');
console.log('ROBOKASSA_MERCHANT_LOGIN:', login || '(пусто!)');
console.log('Пароль #1 задан:', Boolean(config.robokassa.password1));
console.log('Пароль #2 задан:', Boolean(config.robokassa.password2));
console.log('PAYMENT_MOCK:', config.paymentMock);
console.log('IsTest=1 в ссылке:', url.includes('IsTest=1') ? 'ДА' : 'нет');
console.log('Receipt в ссылке:', url.includes('Receipt=') ? 'ДА' : 'нет');
console.log('Пример ссылки (проверьте MerchantLogin):');
console.log(url);
