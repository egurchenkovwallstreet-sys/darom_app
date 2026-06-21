-- Сессии «Мобильная авторизация» SMS Aero
-- cat backend/db/migrate_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom

CREATE TABLE IF NOT EXISTS mobile_id_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aero_id INTEGER NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  account_phone TEXT NOT NULL,
  verify_phone TEXT NOT NULL,
  status INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS mobile_id_sessions_aero_id_idx ON mobile_id_sessions (aero_id);
CREATE INDEX IF NOT EXISTS mobile_id_sessions_user_idx ON mobile_id_sessions (user_id, created_at DESC);
