const crypto = require('crypto');
const db = require('../db/pool');

const VERIFY_TOKEN_TTL_MINUTES = 15;

async function storeVerifyToken(normalizedPhone) {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + VERIFY_TOKEN_TTL_MINUTES * 60 * 1000);

  await db.query(
    `
    INSERT INTO phone_verify_tokens (phone, token, expires_at)
    VALUES ($1, $2, $3)
    ON CONFLICT (phone) DO UPDATE SET
      token = EXCLUDED.token,
      expires_at = EXCLUDED.expires_at,
      created_at = NOW()
    `,
    [normalizedPhone, token, expiresAt]
  );

  return { token, expires_in: VERIFY_TOKEN_TTL_MINUTES * 60 };
}

async function consumeVerifyToken(normalizedPhone, token) {
  const result = await db.query(
    'SELECT token, expires_at FROM phone_verify_tokens WHERE phone = $1',
    [normalizedPhone]
  );
  const row = result.rows[0];

  if (!row || row.token !== token) {
    return false;
  }

  if (new Date(row.expires_at) < new Date()) {
    await db.query('DELETE FROM phone_verify_tokens WHERE phone = $1', [normalizedPhone]);
    return false;
  }

  await db.query('DELETE FROM phone_verify_tokens WHERE phone = $1', [normalizedPhone]);
  return true;
}

module.exports = {
  VERIFY_TOKEN_TTL_MINUTES,
  storeVerifyToken,
  consumeVerifyToken,
};
