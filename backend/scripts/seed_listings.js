/**
 * Добавить тестовые объявления пользователю (обходит лимит — только для разработки).
 *
 * Использование:
 *   node scripts/seed_listings.js +79138931428 16
 *
 * Второй аргумент — сколько ВСЕГО активных объявлений должно быть у пользователя.
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const db = require('../src/db/pool');
const { normalizePhone } = require('../src/utils/phone');

async function main() {
  const phoneArg = process.argv[2];
  const targetTotal = Number(process.argv[3] || 16);

  if (!phoneArg) {
    console.error('Укажите телефон: node scripts/seed_listings.js +79138931428 16');
    process.exit(1);
  }

  const phone = normalizePhone(phoneArg);

  const userResult = await db.query(
    'SELECT id, name, phone FROM users WHERE phone = $1',
    [phone],
  );
  const user = userResult.rows[0];
  if (!user) {
    console.error(`Пользователь не найден: ${phone}`);
    process.exit(1);
  }

  const countResult = await db.query(
    `SELECT COUNT(*)::int AS cnt FROM listings
     WHERE user_id = $1 AND status IN ('active', 'reserved')`,
    [user.id],
  );
  const current = countResult.rows[0].cnt;
  const toAdd = targetTotal - current;

  if (toAdd <= 0) {
    console.log(`${user.name} (${phone}): уже ${current} активных объявлений — ничего не добавлено.`);
    process.exit(0);
  }

  for (let i = 1; i <= toAdd; i += 1) {
    const n = current + i;
    await db.query(
      `
      INSERT INTO listings (user_id, title, description, category, subcategory, photos_count, location)
      VALUES (
        $1,
        $2,
        $3,
        'Одежда',
        'Мужская',
        0,
        ST_SetSRID(ST_MakePoint(37.6173, 55.7558), 4326)::geography
      )
      `,
      [
        user.id,
        `Тестовое объявление №${n}`,
        `Автоматически создано для проверки лимита. Объявление номер ${n}.`,
      ],
    );
  }

  const afterResult = await db.query(
    `SELECT COUNT(*)::int AS cnt FROM listings
     WHERE user_id = $1 AND status IN ('active', 'reserved')`,
    [user.id],
  );

  console.log(
    `Готово: ${user.name} (${phone}) — было ${current}, добавлено ${toAdd}, сейчас ${afterResult.rows[0].cnt} активных.`,
  );
  process.exit(0);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
