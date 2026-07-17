-- Ежедневная статистика для super_admin + активность пользователей
-- VNC: cd /opt/darom_app && cat backend/db/migrate_admin_daily_reports.sql | docker exec -i darom_db psql -U darom -d darom
-- После: pm2 restart darom-api --update-env

ALTER TABLE users ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS partner_since TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS users_last_active_idx ON users (last_active_at DESC);

UPDATE users u
SET partner_since = pac.used_at
FROM partner_activation_codes pac
WHERE pac.used_by_user_id = u.id
  AND u.is_partner = TRUE
  AND u.partner_since IS NULL;

CREATE TABLE IF NOT EXISTS admin_daily_reports (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_date   DATE NOT NULL UNIQUE,
  title         VARCHAR(200) NOT NULL,
  body_text     TEXT NOT NULL,
  body_html     TEXT NOT NULL,
  stats_json    JSONB NOT NULL,
  email_sent_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS admin_daily_reports_date_idx
  ON admin_daily_reports (report_date DESC);
