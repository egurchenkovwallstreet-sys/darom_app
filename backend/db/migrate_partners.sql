-- Партнёры (блогеры) и реферальная система
-- cat backend/db/migrate_partners.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE users ADD COLUMN IF NOT EXISTS is_partner BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS partner_public_code VARCHAR(16);
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by_partner_id UUID REFERENCES users(id);

CREATE UNIQUE INDEX IF NOT EXISTS users_partner_public_code_idx
  ON users (partner_public_code)
  WHERE partner_public_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS users_referred_by_partner_idx
  ON users (referred_by_partner_id)
  WHERE referred_by_partner_id IS NOT NULL;

-- Коды активации партнёра (выдаёт администратор)
CREATE TABLE IF NOT EXISTS partner_activation_codes (
  code            VARCHAR(32) PRIMARY KEY,
  label           VARCHAR(120),
  used_by_user_id UUID REFERENCES users(id),
  used_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Оплаты привлечённых пользователей (для комиссии партнёру)
CREATE TABLE IF NOT EXISTS partner_payments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  partner_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  payment_type          VARCHAR(32) NOT NULL,
  amount_rub            INT NOT NULL,
  partner_commission_rub INT NOT NULL,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS partner_payments_partner_idx
  ON partner_payments (partner_id, created_at DESC);
