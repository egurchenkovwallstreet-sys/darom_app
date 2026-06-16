-- Блок B: бронирование, счётчики сделок
-- Для существующей БД: docker exec -i darom_db psql -U darom -d darom < backend/db/migrate_4b.sql

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS items_given INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS items_taken INTEGER NOT NULL DEFAULT 0;

ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS reserved_by_user_id UUID REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS reserved_until TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS listings_reserved_until_idx ON listings (reserved_until);

UPDATE users u SET items_given = sub.cnt
FROM (
  SELECT user_id, COUNT(*)::int AS cnt
  FROM listings WHERE status = 'given' GROUP BY user_id
) sub
WHERE u.id = sub.user_id;
