-- Run this in your Supabase SQL Editor

-- 1. User data table linked to auth.users
CREATE TABLE user_data (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tagar_id TEXT UNIQUE NOT NULL,
  profile_name TEXT,
  username TEXT UNIQUE,
  profile_picture TEXT,
  banner_picture TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Auto-assign tagar_id on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_data (id, tagar_id)
  VALUES (
    NEW.id,
    'tag_#' || substr(md5(random()::text), 1, 6)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger fires after each auth.users insert
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
