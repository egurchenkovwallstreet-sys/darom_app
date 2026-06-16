const { updateDonorLevel } = require('./donor_level');

async function recalcUserRating(db, userId) {
  const avgResult = await db.query(
    `
    SELECT COALESCE(ROUND(AVG(score)::numeric, 1), 5.0) AS avg
    FROM ratings
    WHERE to_user_id = $1
    `,
    [userId],
  );

  const avg = Number(avgResult.rows[0].avg);
  const shadowBanned = avg < 4.0;

  await db.query(
    `
    UPDATE users
    SET rating = $2, is_shadow_banned = $3
    WHERE id = $1
    `,
    [userId, avg, shadowBanned],
  );

  await updateDonorLevel(db, userId);

  return { rating: avg, is_shadow_banned: shadowBanned };
}

module.exports = { recalcUserRating };
