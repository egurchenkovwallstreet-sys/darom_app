const crypto = require('crypto');
const db = require('../db/pool');
const { normalizePhone } = require('../utils/phone');

const SESSION_TTL_DAYS = 30;

function getBearerToken(req) {
  const header = req.headers.authorization;
  if (header?.startsWith('Bearer ')) {
    return header.slice(7).trim();
  }
  return req.headers['x-user-token'] ?? null;
}

function isBlockedUser(user) {
  if (!user) return false;
  if (user.is_blocked_permanent) return true;
  if (user.blocked_until && new Date(user.blocked_until) > new Date()) return true;
  return false;
}

async function createUserSession(userId) {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + SESSION_TTL_DAYS * 24 * 60 * 60 * 1000);

  await db.query(
    `
    INSERT INTO user_sessions (token, user_id, expires_at)
    VALUES ($1, $2, $3)
    `,
    [token, userId, expiresAt]
  );

  return {
    token,
    expires_at: expiresAt.toISOString(),
  };
}

async function getUserSession(token) {
  if (!token) return null;

  const result = await db.query(
    `
    SELECT
      s.token,
      s.expires_at,
      s.user_id,
      u.id,
      u.phone,
      u.name,
      u.is_blocked_permanent,
      u.blocked_until
    FROM user_sessions s
    JOIN users u ON u.id = s.user_id
    WHERE s.token = $1
    `,
    [token]
  );

  const row = result.rows[0];
  if (!row || new Date(row.expires_at) < new Date()) {
    return null;
  }

  return {
    token: row.token,
    userId: row.user_id,
    expiresAt: row.expires_at,
    user: {
      id: row.id,
      phone: row.phone,
      name: row.name,
      is_blocked_permanent: row.is_blocked_permanent,
      blocked_until: row.blocked_until,
    },
  };
}

async function requireUserSession(req, res, next) {
  try {
    const token = getBearerToken(req);
    const session = await getUserSession(token);

    if (!session) {
      return res.status(401).json({ error: 'Нужен вход в приложение' });
    }

    if (isBlockedUser(session.user)) {
      return res.status(403).json({ error: 'Аккаунт заблокирован. Обратитесь в поддержку.' });
    }

    req.userSession = session;
    return next();
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
}

function phoneMatchesSession(req, phoneRaw) {
  if (!phoneRaw || !req.userSession?.user?.phone) return false;
  return normalizePhone(phoneRaw) === req.userSession.user.phone;
}

function rejectMismatchedPhone(req, res, phoneRaw) {
  if (phoneMatchesSession(req, phoneRaw)) {
    return true;
  }
  res.status(403).json({ error: 'Недостаточно прав для этого аккаунта' });
  return false;
}

module.exports = {
  SESSION_TTL_DAYS,
  getBearerToken,
  createUserSession,
  getUserSession,
  requireUserSession,
  isBlockedUser,
  phoneMatchesSession,
  rejectMismatchedPhone,
};
