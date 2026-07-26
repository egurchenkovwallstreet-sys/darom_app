/** Токен сессии Flash Call / Mobile ID — из заголовка (предпочтительно) или legacy query/body. */
function readVerifySessionToken(req, { allowBody = false, allowQuery = false } = {}) {
  const header = req.headers['x-verify-session-token'];
  if (header && String(header).trim()) {
    return String(header).trim();
  }

  if (allowQuery && req.query?.session_token) {
    return String(req.query.session_token).trim();
  }

  if (allowBody && req.body?.session_token) {
    return String(req.body.session_token).trim();
  }

  return null;
}

module.exports = { readVerifySessionToken };
