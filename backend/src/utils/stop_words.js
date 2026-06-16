/** Запрещённые слова и паттерны в объявлениях (коммерция, ссылки). */
const STOP_WORDS = [
  'продам',
  'продаю',
  'куплю',
  'купить',
  'цена',
  'руб',
  'рубл',
  '₽',
  '$',
  '€',
  'скидка',
  'оплата',
  'наличные',
  'перевод',
  'telegram',
  'телеграм',
  'whatsapp',
  'viber',
  'http',
  'https',
  'www.',
  '.ru/',
  'avito',
  'wildberries',
  'ozon',
];

function findStopWord(text) {
  const lower = String(text).toLowerCase();

  for (const word of STOP_WORDS) {
    if (lower.includes(word)) {
      return word;
    }
  }

  return null;
}

function validateListingText(title, description) {
  const combined = `${title} ${description}`;
  const found = findStopWord(combined);

  if (found) {
    return {
      ok: false,
      error: `Текст содержит запрещённое слово или ссылку: «${found}». «Даром» — только бесплатная передача вещей.`,
    };
  }

  return { ok: true };
}

module.exports = { findStopWord, validateListingText, STOP_WORDS };
