-- Этап 4D: лимиты заборов для получателей (7/мес, пакет +10)
-- Get-Content backend\db\migrate_4d.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS pickups_this_month INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pickup_month VARCHAR(7),
  ADD COLUMN IF NOT EXISTS pickup_credits INTEGER NOT NULL DEFAULT 0;
