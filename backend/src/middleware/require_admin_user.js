const db = require('../db/pool');
const { requireUserSession } = require('./user_auth');
const { getAdminUserByPhone } = require('../utils/admin_auth');

async function attachAdminUser(req, res, next) {
  try {
    const adminUser = await getAdminUserByPhone(db, req.userSession.user.phone);
    if (!adminUser) {
      return res.status(403).json({ error: 'Доступ только для администратора' });
    }
    req.adminUser = adminUser;
    return next();
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
}

function requireSuperAdminUser(req, res, next) {
  if (req.adminUser?.role !== 'super_admin') {
    return res.status(403).json({ error: 'Доступ только для главного администратора' });
  }
  return next();
}

const requireAdminUserSession = [requireUserSession, attachAdminUser];
const requireSuperAdminUserSession = [requireUserSession, attachAdminUser, requireSuperAdminUser];

module.exports = {
  attachAdminUser,
  requireSuperAdminUser,
  requireAdminUserSession,
  requireSuperAdminUserSession,
};
