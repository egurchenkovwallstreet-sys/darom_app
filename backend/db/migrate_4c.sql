-- Этап 4C: рейтинг, жалобы, уровни
-- Get-Content backend\db\migrate_4c.sql | docker exec -i darom_db psql -U darom -d darom

CREATE TABLE IF NOT EXISTS deals (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id    UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  donor_id      UUID NOT NULL REFERENCES users(id),
  recipient_id  UUID REFERENCES users(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS deals_listing_idx ON deals (listing_id);

CREATE TABLE IF NOT EXISTS ratings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id       UUID NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  from_user_id  UUID NOT NULL REFERENCES users(id),
  to_user_id    UUID NOT NULL REFERENCES users(id),
  score         SMALLINT NOT NULL CHECK (score >= 1 AND score <= 5),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (deal_id, from_user_id)
);

CREATE TABLE IF NOT EXISTS listing_reports (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id    UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  reporter_id   UUID NOT NULL REFERENCES users(id),
  reason        VARCHAR(500),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (listing_id, reporter_id)
);

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_shadow_banned BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS reports_count INTEGER NOT NULL DEFAULT 0;
