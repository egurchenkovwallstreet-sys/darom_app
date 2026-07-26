const config = require('../config');

const SESSION_COOKIE = 'darom_session';

function cookieSecure() {
  const base = String(config.publicBaseUrl || '');
  return base.startsWith('https://') || process.env.NODE_ENV === 'production';
}

function setSessionCookie(res, token) {
  res.cookie(SESSION_COOKIE, token, {
    httpOnly: true,
    secure: cookieSecure(),
    sameSite: 'lax',
    maxAge: 30 * 24 * 60 * 60 * 1000,
    path: '/api',
  });
}

function clearSessionCookie(res) {
  res.clearCookie(SESSION_COOKIE, {
    httpOnly: true,
    secure: cookieSecure(),
    sameSite: 'lax',
    path: '/api',
  });
}

function readSessionCookie(req) {
  const value = req.cookies?.[SESSION_COOKIE];
  if (!value) return null;
  const trimmed = String(value).trim();
  return trimmed.length > 0 ? trimmed : null;
}

module.exports = {
  SESSION_COOKIE,
  setSessionCookie,
  clearSessionCookie,
  readSessionCookie,
};
