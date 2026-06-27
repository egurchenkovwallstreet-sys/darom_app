-- Этап J-C: блокировка PIN после серии неверных попыток (на аккаунт, не только IP)
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_failed_attempts INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_locked_until TIMESTAMPTZ;
