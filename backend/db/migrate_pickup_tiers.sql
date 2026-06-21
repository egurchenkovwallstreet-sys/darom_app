-- Лестница платных пакетов заборов (149 → 299 → 499), сброс каждый месяц
-- cat backend/db/migrate_pickup_tiers.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS pickup_paid_tiers_bought INTEGER NOT NULL DEFAULT 0;
