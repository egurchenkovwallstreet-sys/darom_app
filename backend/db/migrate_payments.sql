-- Заказы Робокассы (InvId, тип, сумма, статус)
-- cat backend/db/migrate_payments.sql | docker exec -i darom_db psql -U darom -d darom

CREATE TABLE IF NOT EXISTS payments (
  id              SERIAL PRIMARY KEY,
  inv_id          BIGINT NOT NULL UNIQUE,
  user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_type    VARCHAR(32) NOT NULL,
  amount_rub      INTEGER NOT NULL,
  tier_at_purchase INTEGER,
  status          VARCHAR(16) NOT NULL DEFAULT 'pending',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  paid_at         TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS payments_user_idx ON payments (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS payments_status_idx ON payments (status, created_at DESC);

CREATE SEQUENCE IF NOT EXISTS payments_inv_id_seq START WITH 1000;
