-- Привязка реферала к блогеру: 365 дней с момента регистрации
-- Get-Content backend\db\migrate_partner_referral_365.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_at TIMESTAMPTZ;

UPDATE users
SET referred_at = COALESCE(created_at, NOW())
WHERE referred_by_partner_id IS NOT NULL
  AND referred_at IS NULL;

CREATE INDEX IF NOT EXISTS users_referred_at_active_idx
  ON users (referred_by_partner_id, referred_at)
  WHERE referred_by_partner_id IS NOT NULL;
