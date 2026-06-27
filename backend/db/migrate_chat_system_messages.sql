-- Системные сообщения в чатах (бронь, подсказки дарителю)
-- VNC: Get-Content backend/db/migrate_chat_system_messages.sql | docker exec -i darom_db psql -U darom -d darom

ALTER TABLE chat_messages
  ADD COLUMN IF NOT EXISTS message_type TEXT NOT NULL DEFAULT 'user';

ALTER TABLE chat_messages
  DROP CONSTRAINT IF EXISTS chat_messages_message_type_check;

ALTER TABLE chat_messages
  ADD CONSTRAINT chat_messages_message_type_check
  CHECK (message_type IN ('user', 'system'));

ALTER TABLE chat_messages
  ALTER COLUMN sender_id DROP NOT NULL;

ALTER TABLE chat_messages
  DROP CONSTRAINT IF EXISTS chat_messages_sender_required;

ALTER TABLE chat_messages
  ADD CONSTRAINT chat_messages_sender_required
  CHECK (
    (message_type = 'user' AND sender_id IS NOT NULL)
    OR (message_type = 'system' AND sender_id IS NULL)
  );
