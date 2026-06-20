-- Ежемесячные выплаты партнёрам: paid_out_at = когда выплачено администратором
-- Get-Content backend\db\migrate_partner_payout_period.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE partner_payments ADD COLUMN IF NOT EXISTS paid_out_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS partner_payments_pending_idx
  ON partner_payments (partner_id, created_at DESC)
  WHERE paid_out_at IS NULL;
