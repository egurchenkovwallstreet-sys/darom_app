-- Доп. пакеты объявлений «Супер даритель» (+10 за каждую покупку 99₽)
-- Get-Content backend\db\migrate_listing_extra_packs.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS listing_extra_packs INT NOT NULL DEFAULT 0;
