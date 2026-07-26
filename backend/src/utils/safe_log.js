/** Логирование без персональных данных и одноразовых кодов. */

function maskPhone(phone) {
  const digits = String(phone ?? '').replace(/\D/g, '');
  if (digits.length < 4) return '***';
  return `***${digits.slice(-4)}`;
}

function maskEmail(email) {
  const value = String(email ?? '').trim();
  const at = value.indexOf('@');
  if (at <= 1) return '***@***';
  return `${value[0]}***${value.slice(at)}`;
}

function logInfo(message) {
  console.log(message);
}

function logWarn(message) {
  console.warn(message);
}

function logSmsMock({ reason } = {}) {
  const suffix = reason ? ` (${reason})` : '';
  logInfo(`[SMS mock] код отправлен${suffix}`);
}

function logPlusofonFlashMockInitiated() {
  logInfo('[Plusofon Flash mock] звонок инициирован (тестовый режим)');
}

function logPlusofonFlashMockCheck() {
  logInfo('[Plusofon Flash mock] проверка PIN (тестовый режим)');
}

function logAdminEmailMock({ to }) {
  logInfo(`[ADMIN EMAIL MOCK] письмо отправлено на ${maskEmail(to)}`);
}

function logAdminEmailSent({ to, host, portLabel }) {
  logInfo(`[ADMIN EMAIL] sent to=${maskEmail(to)} via ${host}:${portLabel}`);
}

module.exports = {
  maskPhone,
  maskEmail,
  logInfo,
  logWarn,
  logSmsMock,
  logPlusofonFlashMockInitiated,
  logPlusofonFlashMockCheck,
  logAdminEmailMock,
  logAdminEmailSent,
};
