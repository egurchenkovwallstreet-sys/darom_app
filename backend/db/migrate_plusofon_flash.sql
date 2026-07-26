-- Плюсofon Flash Call: provider + flash_key в mobile_id_sessions
-- cat backend/db/migrate_plusofon_flash.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE mobile_id_sessions
  ALTER COLUMN aero_id DROP NOT NULL;

DROP INDEX IF EXISTS mobile_id_sessions_aero_id_idx;
CREATE UNIQUE INDEX IF NOT EXISTS mobile_id_sessions_aero_id_idx
  ON mobile_id_sessions (aero_id)
  WHERE aero_id IS NOT NULL;

ALTER TABLE mobile_id_sessions
  ADD COLUMN IF NOT EXISTS provider TEXT NOT NULL DEFAULT 'mobile_id';

ALTER TABLE mobile_id_sessions
  ADD COLUMN IF NOT EXISTS flash_key TEXT;

ALTER TABLE mobile_id_sessions
  ADD COLUMN IF NOT EXISTS flash_pin TEXT;

CREATE INDEX IF NOT EXISTS mobile_id_sessions_provider_idx
  ON mobile_id_sessions (provider, created_at DESC);
