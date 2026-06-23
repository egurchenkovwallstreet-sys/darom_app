async function expireReservations(db) {
  await db.query(`
    UPDATE listings
    SET
      status = 'active',
      reserved_by_user_id = NULL,
      reserved_until = NULL
    WHERE status = 'reserved'
      AND reserved_until IS NOT NULL
      AND reserved_until < NOW()
  `);
}

async function getUserByPhone(db, phone) {
  const normalizedPhone = phone; // already normalized by caller
  const result = await db.query(
    'SELECT id, phone, name, is_founder, super_donor_until, listing_extra_packs, items_given, items_taken, real_phone_verified_at FROM users WHERE phone = $1',
    [normalizedPhone]
  );
  return result.rows[0] ?? null;
}

async function fetchListingById(db, listingId) {
  const result = await db.query(
    `
    SELECT
      l.id,
      l.user_id AS owner_id,
      l.title,
      l.description,
      l.category,
      l.subcategory,
      l.photos_count,
      l.status,
      l.reserved_by_user_id,
      l.reserved_until,
      u.name AS author_name,
      u.donor_level AS author_level,
      u.rating AS author_rating,
      ${photoUrlsField}
    FROM listings l
    JOIN users u ON u.id = l.user_id
    WHERE l.id = $1
    `,
    [listingId]
  );
  return result.rows[0] ?? null;
}

const photoUrlsField = `
  COALESCE(
    (
      SELECT json_agg(p.url ORDER BY p.sort_order)
      FROM listing_photos p
      WHERE p.listing_id = l.id
    ),
    '[]'::json
  ) AS photo_urls`;

const { normalizePhotoUrls } = require('../utils/photo_urls');

function parsePhotoUrls(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value.map(String);
  return [];
}

function mapListingRow(row) {
  const item = {
    id: row.id,
    owner_id: row.owner_id,
    title: row.title,
    description: row.description,
    category: row.category,
    subcategory: row.subcategory,
    photos_count: row.photos_count,
    photo_urls: normalizePhotoUrls(parsePhotoUrls(row.photo_urls)),
    status: row.status,
    reserved_until: row.reserved_until,
    author_name: row.author_name,
    author_level: row.author_level,
    author_rating: row.author_rating,
    author_is_founder: Boolean(row.author_is_founder),
    distance_km: row.distance_km ?? 0,
  };

  if (row.lat != null && row.lng != null) {
    item.lat = Number(row.lat);
    item.lng = Number(row.lng);
  }

  return item;
}

module.exports = {
  expireReservations,
  getUserByPhone,
  fetchListingById,
  mapListingRow,
  photoUrlsField,
};
