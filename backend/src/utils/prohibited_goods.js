/**
 * Автомодерация: товары, запрещённые законом РФ или требующие лицензии/разрешений.
 * Проверяются название, описание, категория и подкатегория объявления.
 */

function normalize(text) {
  return String(text)
    .toLowerCase()
    .replace(/ё/g, 'е')
    .replace(/\s+/g, ' ')
    .trim();
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** Одно слово — только целиком (чтобы «виноград» не совпал с «вино»). */
function matchesWholeWord(normalized, word) {
  const re = new RegExp(
    `(?:^|[^\\p{L}\\p{N}])${escapeRegex(word)}(?:[^\\p{L}\\p{N}]|$)`,
    'iu',
  );
  return re.test(` ${normalized} `);
}

function matchesKeyword(normalized, keyword) {
  const k = keyword.replace(/ё/g, 'е');
  if (k.includes(' ')) {
    return normalized.includes(k);
  }
  if (k.length <= 4) {
    return matchesWholeWord(normalized, k);
  }
  return normalized.includes(k);
}

const PROHIBITED_RULES = [
  {
    kind: 'illegal',
    label: 'запрещён законом РФ',
    keywords: [
      'наркотик',
      'наркота',
      'гашиш',
      'героин',
      'кокаин',
      'марихуан',
      'каннабис',
      'амфетамин',
      'метамфетамин',
      'лсд',
      'mdma',
      'экстази',
      'спайс',
      'мефедрон',
      'психотроп',
      'оружие',
      'огнестрел',
      'пистолет',
      'револьвер',
      'автомат калаш',
      'ак-47',
      'карабин',
      'ружье',
      'ружья',
      'боеприпас',
      'гранатомет',
      'взрывчат',
      'тротил',
      'радиоактив',
      'уран',
      'плутоний',
      'орган человека',
      'торговля органами',
      'контрафакт',
      'подделка бренд',
      'детская порн',
      'банковская карта',
      'cvv карты',
      'данные карты',
    ],
  },
  {
    kind: 'licensed',
    label: 'требуются разрешения или лицензия',
    keywords: [
      'лекарств',
      'лекарство',
      'лекарственн',
      'медикамент',
      'рецептурн',
      'фармацевт',
      'аптечный препарат',
      'антибиотик',
      'анальгин',
      'парацетамол',
      'ибупрофен',
      'нурофен',
      'аспирин',
      'инсулин',
      'гормональн препарат',
      'психотропн препарат',
      'ветеринарн препарат',
      'ветпрепарат',
      'алкоголь',
      'водка',
      'виски',
      'коньяк',
      'текила',
      'шампанское',
      'ликер',
      'ликёр',
      'пиво',
      'вино',
      'ром',
      'этиловый спирт',
      'питьевой спирт',
      '\u0441\u0430\u043c\u043e\u0433\u043e\u043d',
      'табак',
      'сигарет',
      'сигарил',
      'снюс',
      'айкос',
      'iqos',
      'glo стики',
      'стики glo',
      'вейп',
      'электронная сигарета',
      'никотин',
      'жидкость для вейпа',
      'пиротехник',
      'фейерверк',
      'салют',
      'пестицид',
      'гербицид',
      'инсектицид',
      'ядохимикат',
      'холодное оружие',
      'боевой нож',
      'нож-кинжал',
      'кинжал',
      'арбалет',
      'травмат',
      'патроны',
      'дефибриллятор',
      'кардиостимулятор',
      'рентген аппарат',
      'медицинский лазер',
    ],
  },
];

function findProhibitedMatch(title, description, category, subcategory) {
  const combined = normalize(
    [title, description, category, subcategory].filter(Boolean).join(' '),
  );

  for (const rule of PROHIBITED_RULES) {
    for (const keyword of rule.keywords) {
      if (matchesKeyword(combined, keyword)) {
        return { rule, keyword };
      }
    }
  }

  return null;
}

function validateProhibitedGoods(title, description, category, subcategory) {
  const match = findProhibitedMatch(title, description, category, subcategory);

  if (!match) {
    return { ok: true };
  }

  const { rule, keyword } = match;
  const reason =
    rule.kind === 'illegal'
      ? 'запрещён к реализации на территории РФ'
      : 'для передачи требуются специальные разрешения или лицензия';

  return {
    ok: false,
    kind: rule.kind,
    keyword,
    error:
      `Объявление не может быть опубликовано: указан товар или формулировка «${keyword}», ` +
      `которые ${reason}. «Даром» — только бесплатная передача обычных бытовых вещей.`,
  };
}

module.exports = {
  PROHIBITED_RULES,
  findProhibitedMatch,
  validateProhibitedGoods,
};
