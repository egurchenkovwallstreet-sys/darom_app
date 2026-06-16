-- Аватар пользователя
-- Get-Content backend\db\migrate_avatar.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;
