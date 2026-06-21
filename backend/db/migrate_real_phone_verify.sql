-- Одноразовое подтверждение реального номера (SMS при первом объявлении или первом сообщении в чат)
-- cat backend/db/migrate_real_phone_verify.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users ADD COLUMN IF NOT EXISTS real_phone_verified_at TIMESTAMPTZ;
