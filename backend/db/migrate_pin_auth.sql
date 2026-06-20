-- Пароль из 4 цифр + периодическое подтверждение номера по SMS
-- Get-Content backend\db\migrate_pin_auth.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_hash VARCHAR(128);
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_set_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMPTZ;

UPDATE users
SET phone_verified_at = COALESCE(phone_verified_at, created_at, NOW())
WHERE phone_verified_at IS NULL;

CREATE TABLE IF NOT EXISTS phone_verify_tokens (
  phone       VARCHAR(20) PRIMARY KEY,
  token       VARCHAR(64) NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS phone_verify_tokens_expires_idx
  ON phone_verify_tokens (expires_at);
