-- Служба поддержки: тикеты и сообщения
-- VNC (Терминал 1):
--   cd /opt/darom_app && Get-Content backend/db/migrate_support.sql | docker exec -i darom_db psql -U darom -d darom
-- Linux VNC:
--   cd /opt/darom_app && cat backend/db/migrate_support.sql | docker exec -i darom_db psql -U darom -d darom
-- После: pm2 restart darom-api --update-env

CREATE TABLE IF NOT EXISTS support_tickets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject     VARCHAR(200),
  status      VARCHAR(20) NOT NULL DEFAULT 'new'
                CHECK (status IN ('new', 'in_progress', 'closed')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS support_tickets_user_idx
  ON support_tickets (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS support_tickets_status_idx
  ON support_tickets (status, updated_at DESC);

CREATE TABLE IF NOT EXISTS support_messages (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id    UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  author_role  VARCHAR(10) NOT NULL CHECK (author_role IN ('user', 'admin')),
  admin_id     UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  body         TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS support_messages_ticket_idx
  ON support_messages (ticket_id, created_at ASC);
