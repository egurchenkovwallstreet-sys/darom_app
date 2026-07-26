-- Согласия пользователя (152-ФЗ) и версии документов.
-- Get-Content backend\db\migrate_privacy_consent.sql | docker exec -i darom_db psql -U darom -d darom
-- На сервере: cat backend/db/migrate_privacy_consent.sql | psql ...

ALTER TABLE users ADD COLUMN IF NOT EXISTS offer_accepted_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS offer_version VARCHAR(32);
ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_consent_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_policy_version VARCHAR(32);
