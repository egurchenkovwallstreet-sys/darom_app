/** Приводит телефон к формату +79001234567 */
function normalizePhone(phone) {
  const digits = String(phone).replace(/\D/g, '');

  if (digits.length === 11 && digits.startsWith('8')) {
    return `+7${digits.slice(1)}`;
  }
  if (digits.length === 11 && digits.startsWith('7')) {
    return `+${digits}`;
  }
  if (digits.length === 10) {
    return `+7${digits}`;
  }

  return `+${digits}`;
}

module.exports = { normalizePhone };
