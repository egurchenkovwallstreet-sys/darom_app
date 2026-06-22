-- Mobile ID для входа в админ-панель (вместо дорогого SMS)
-- cat backend/db/migrate_admin_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE admin_login_challenges
  ALTER COLUMN sms_code DROP NOT NULL;

ALTER TABLE admin_login_challenges
  ADD COLUMN IF NOT EXISTS mobile_id_session_id UUID REFERENCES mobile_id_sessions(id) ON DELETE SET NULL;

ALTER TABLE admin_login_challenges
  ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS admin_login_challenges_mobile_idx
  ON admin_login_challenges (mobile_id_session_id);
