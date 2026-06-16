-- Тариф «Супер даритель» (99₽ / 30 дней → +10 объявлений)
-- Get-Content backend\db\migrate_super_donor.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS super_donor_until TIMESTAMPTZ;
