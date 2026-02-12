-- 20260210_gap_fix_v2.sql
-- Fixes critical gaps identified in Phase 7 E2E Verification
-- Includes CREATE TABLE statements for missing relations

-- 1. Ensure basic tables exist (Social Module)
CREATE TABLE IF NOT EXISTS post_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- 2. Add tech_score and metadata to posts
ALTER TABLE posts ADD COLUMN IF NOT EXISTS tech_score FLOAT DEFAULT 0;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS strain_tag TEXT;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS grow_id UUID;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS day_number INT;

-- 3. Add moderation flags to comments
ALTER TABLE post_comments ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT FALSE;
ALTER TABLE post_comments ADD COLUMN IF NOT EXISTS is_flagged BOOLEAN DEFAULT FALSE;

-- 4. Add FCM tokens to profiles for Push Notifications (Phase 5)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_platform TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS notification_settings JSONB DEFAULT '{"daily_reminders": true, "alerts": true, "social": true}';

-- 5. Create reports table (referenced in social.py)
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES profiles(id),
    post_id UUID REFERENCES posts(id),
    comment_id UUID REFERENCES post_comments(id),
    reason TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Create badges/achievements tables (Gamification)
CREATE TABLE IF NOT EXISTS badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    condition_type TEXT,
    condition_value INT,
    xp_reward INT DEFAULT 50,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id),
    badge_id UUID REFERENCES badges(id),
    awarded_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- 7. Add RPC functions for counters if they don't exist
-- (These are often needed by Supabase client logic)
CREATE OR REPLACE FUNCTION increment_likes(post_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE posts
  SET likes_count = likes_count + 1
  WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_likes(post_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE posts
  SET likes_count = GREATEST(likes_count - 1, 0)
  WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_comments(post_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE posts
  SET comments_count = comments_count + 1
  WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql;
