-- Mobile ID для регистрации партнёров (user_id может быть NULL до создания аккаунта)
-- ВАЖНО: сначала выполните migrate_mobile_id.sql (создаёт таблицу mobile_id_sessions)!
-- cat backend/db/migrate_partner_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE mobile_id_sessions
  ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE mobile_id_sessions
  ADD COLUMN IF NOT EXISTS partner_activation_code TEXT;

ALTER TABLE mobile_id_sessions
  ADD COLUMN IF NOT EXISTS purpose TEXT NOT NULL DEFAULT 'active_verify';

CREATE INDEX IF NOT EXISTS mobile_id_sessions_purpose_phone_idx
  ON mobile_id_sessions (purpose, verify_phone, created_at DESC);
