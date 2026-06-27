/** Очистка пользовательского текста (чаты, объявления) — этап J-E. */
function sanitizeUserText(raw) {
  let text = String(raw ?? '');
  text = text.replace(/\0/g, '');
  text = text.replace(/<[^>]*>/g, '');
  text = text.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
  return text.trim();
}

function containsDangerousMarkup(text) {
  return /(<script|javascript:|on\w+\s*=|<iframe|<object|<embed)/i.test(text);
}

module.exports = { sanitizeUserText, containsDangerousMarkup };
