/** Уровни дарителя по ТЗ (раздел 8). */
function computeDonorLevel(itemsGiven, rating) {
  const given = Number(itemsGiven) || 0;
  const rate = Number(rating) || 5;

  if (given >= 100 && rate >= 4.8) {
    return 'Самое доброе сердце';
  }
  if (given >= 50) {
    return 'Благотворитель';
  }
  if (given >= 20) {
    return 'Щедрый';
  }
  if (given >= 5 && rate >= 4.0) {
    return 'Активный';
  }

  return 'Новичок';
}

async function updateDonorLevel(db, userId) {
  const result = await db.query(
    'SELECT items_given, rating FROM users WHERE id = $1',
    [userId],
  );
  const row = result.rows[0];
  if (!row) return;

  const level = computeDonorLevel(row.items_given, row.rating);
  await db.query('UPDATE users SET donor_level = $2 WHERE id = $1', [userId, level]);
}

module.exports = { computeDonorLevel, updateDonorLevel };
