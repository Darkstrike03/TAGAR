CREATE TABLE IF NOT EXISTS message_relay (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE message_relay ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own sent messages"
  ON message_relay FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can read messages addressed to them"
  ON message_relay FOR SELECT
  TO authenticated
  USING (auth.uid() = receiver_id);

CREATE POLICY "Users can delete messages they sent or received"
  ON message_relay FOR DELETE
  TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE INDEX IF NOT EXISTS idx_message_relay_receiver_id ON message_relay(receiver_id);
CREATE INDEX IF NOT EXISTS idx_message_relay_created_at ON message_relay(created_at);

ALTER PUBLICATION supabase_realtime ADD TABLE message_relay;
