-- Админ-панель: 2FA, жалобы на чаты, блокировки
-- cat backend/db/migrate_admin.sql | docker exec -i darom_db psql -U darom -d darom

CREATE TABLE IF NOT EXISTS admin_users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone           VARCHAR(20) NOT NULL UNIQUE,
  email           VARCHAR(255) NOT NULL,
  role            VARCHAR(24) NOT NULL DEFAULT 'super_admin',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_login_challenges (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id        UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  sms_code        VARCHAR(8) NOT NULL,
  email_code      VARCHAR(8) NOT NULL,
  sms_verified    BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS admin_login_challenges_admin_idx
  ON admin_login_challenges (admin_id, created_at DESC);

CREATE TABLE IF NOT EXISTS admin_sessions (
  token           VARCHAR(64) PRIMARY KEY,
  admin_id        UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  role            VARCHAR(24) NOT NULL,
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  reporter_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason          TEXT,
  status          VARCHAR(20) NOT NULL DEFAULT 'open',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (conversation_id, reporter_id)
);

CREATE INDEX IF NOT EXISTS chat_reports_status_idx ON chat_reports (status, created_at DESC);

CREATE TABLE IF NOT EXISTS moderation_actions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id        UUID REFERENCES admin_users(id),
  target_type     VARCHAR(20) NOT NULL,
  target_id       UUID NOT NULL,
  action          VARCHAR(24) NOT NULL,
  days            INT,
  reason          TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS blocked_until TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_blocked_permanent BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE listings ADD COLUMN IF NOT EXISTS blocked_until TIMESTAMPTZ;
ALTER TABLE listings ADD COLUMN IF NOT EXISTS is_blocked_permanent BOOLEAN NOT NULL DEFAULT FALSE;

-- Главный админ (телефон/email можно переопределить через env при первом входе)
INSERT INTO admin_users (phone, email, role)
VALUES ('79138931428', 'e.gurchenkov@yandex.ru', 'super_admin')
ON CONFLICT (phone) DO UPDATE SET
  email = EXCLUDED.email,
  role = EXCLUDED.role,
  is_active = TRUE;
