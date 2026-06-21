-- Run in Supabase SQL Editor after 001_user_data.sql

-- 1. Contacts table (bidirectional — each direction stored separately)
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  contact_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  contact_tagar_id TEXT NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, contact_user_id)
);

-- 2. Friend requests
CREATE TABLE friend_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  from_tagar_id TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Row-level security
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own contacts"
  ON contacts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own contacts"
  ON contacts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own friend requests"
  ON friend_requests FOR SELECT
  USING (auth.uid() = to_user_id OR auth.uid() = from_user_id);

CREATE POLICY "Users can insert friend requests"
  ON friend_requests FOR INSERT
  WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Users can update their own received requests"
  ON friend_requests FOR UPDATE
  USING (auth.uid() = to_user_id);
