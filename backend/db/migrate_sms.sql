-- Этап 5: SMS-коды для входа
-- Get-Content backend\db\migrate_sms.sql | docker exec -i darom_db psql -U darom -d darom

CREATE TABLE IF NOT EXISTS sms_codes (
  phone       VARCHAR(20) PRIMARY KEY,
  code        VARCHAR(6) NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS sms_codes_expires_idx ON sms_codes (expires_at);
