-- Порядковые коды партнёров 0001–1000 (следующий открывается после регистрации предыдущего)
-- Get-Content backend\db\migrate_partner_sequential_codes.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE partner_activation_codes ADD COLUMN IF NOT EXISTS sequence_num INT;

CREATE UNIQUE INDEX IF NOT EXISTS partner_activation_codes_sequence_idx
  ON partner_activation_codes (sequence_num)
  WHERE sequence_num IS NOT NULL;

INSERT INTO partner_activation_codes (code, sequence_num)
SELECT LPAD(i::text, 4, '0'), i
FROM generate_series(1, 1000) AS i
ON CONFLICT (code) DO UPDATE SET sequence_num = EXCLUDED.sequence_num;

-- Удалить старые произвольные коды вне диапазона 0001–1000, если они не использованы
DELETE FROM partner_activation_codes
WHERE sequence_num IS NULL
  AND used_by_user_id IS NULL;
