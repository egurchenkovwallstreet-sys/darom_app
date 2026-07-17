-- Прочитанные сообщения в поддержке (бейдж «новые»)
-- VNC (Терминал 1):
--   cd /opt/darom_app && cat backend/db/migrate_support_reads.sql | docker exec -i darom_db psql -U darom -d darom
-- После: pm2 restart darom-api --update-env

CREATE TABLE IF NOT EXISTS support_ticket_reads (
  ticket_id     UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  reader_role   VARCHAR(10) NOT NULL CHECK (reader_role IN ('user', 'admin')),
  reader_id     UUID NOT NULL,
  last_read_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (ticket_id, reader_role, reader_id)
);

CREATE INDEX IF NOT EXISTS support_ticket_reads_reader_idx
  ON support_ticket_reads (reader_role, reader_id, last_read_at DESC);
