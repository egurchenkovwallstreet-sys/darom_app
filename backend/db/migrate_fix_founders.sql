-- Первые 1000 зарегистрированных пользователей — основатели (is_founder).
-- На ПК:
-- Get-Content backend\db\migrate_fix_founders.sql | docker exec -i darom_db psql -U darom -d darom
-- На сервере (VNC): bash backend/scripts/run_all_migrations.sh или только этот файл.

UPDATE users SET is_founder = FALSE;

UPDATE users SET is_founder = TRUE
WHERE id IN (
  SELECT id FROM users ORDER BY created_at ASC, id ASC LIMIT 1000
);
