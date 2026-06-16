const { Pool } = require('pg');
const config = require('../config');

const pool = new Pool({
  connectionString: config.databaseUrl,
});

async function query(text, params) {
  return pool.query(text, params);
}

async function checkConnection() {
  const result = await pool.query('SELECT NOW() AS now, PostGIS_Version() AS postgis');
  return result.rows[0];
}

module.exports = {
  pool,
  query,
  checkConnection,
};
