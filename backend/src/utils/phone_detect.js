/** Похоже ли сообщение на передачу номера телефона (РФ). */
const PHONE_PATTERNS = [
  /(?:\+7|8|7)[\s(–-]*\d{3}[\s)–-]*\d{3}[\s–-]*\d{2}[\s–-]*\d{2}/,
  /\b9\d{2}[\s–-]?\d{3}[\s–-]?\d{2}[\s–-]?\d{2}\b/,
  /\b\d{10,11}\b/,
];

function containsPhoneNumber(text) {
  const value = String(text ?? '');
  return PHONE_PATTERNS.some((pattern) => pattern.test(value));
}

module.exports = { containsPhoneNumber };
