const TTL_MS = Number(process.env.SUBCATEGORY_COUNTS_CACHE_MS || 60 * 1000);

/** @type {Map<string, { counts: object, expiresAt: number }>} */
const cache = new Map();

function getSubcategoryCounts(category) {
  const entry = cache.get(category);
  if (!entry || Date.now() >= entry.expiresAt) {
    return null;
  }
  return entry.counts;
}

function setSubcategoryCounts(category, counts) {
  cache.set(category, { counts, expiresAt: Date.now() + TTL_MS });
}

function invalidateSubcategoryCounts(category = null) {
  if (category) {
    cache.delete(category);
    cache.delete('Для дома');
    return;
  }
  cache.clear();
}

module.exports = {
  getSubcategoryCounts,
  setSubcategoryCounts,
  invalidateSubcategoryCounts,
};
