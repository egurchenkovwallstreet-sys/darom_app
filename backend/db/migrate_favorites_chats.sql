-- Избранное и чаты
-- Get-Content backend\db\migrate_favorites_chats.sql | docker exec -i darom_db psql -U darom -d darom

CREATE TABLE IF NOT EXISTS favorites (
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  listing_id  UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, listing_id)
);

CREATE INDEX IF NOT EXISTS favorites_user_idx ON favorites (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS conversations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id    UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  donor_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (listing_id, recipient_id)
);

CREATE INDEX IF NOT EXISTS conversations_donor_idx ON conversations (donor_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS conversations_recipient_idx ON conversations (recipient_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS chat_messages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body             TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS chat_messages_conversation_idx
  ON chat_messages (conversation_id, created_at ASC);
