-- Run in Supabase SQL Editor

CREATE OR REPLACE FUNCTION accept_friend_request(
  p_request_id UUID,
  p_from_user_id UUID,
  p_to_user_id UUID,
  p_from_tagar_id TEXT,
  p_to_tagar_id TEXT
)
RETURNS void AS $$
BEGIN
  -- Update request status
  UPDATE friend_requests
  SET status = 'accepted', updated_at = NOW()
  WHERE id = p_request_id;

  -- Add bidirectional contacts
  INSERT INTO contacts (user_id, contact_user_id, contact_tagar_id)
  VALUES (p_to_user_id, p_from_user_id, p_from_tagar_id);

  INSERT INTO contacts (user_id, contact_user_id, contact_tagar_id)
  VALUES (p_from_user_id, p_to_user_id, p_to_tagar_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
