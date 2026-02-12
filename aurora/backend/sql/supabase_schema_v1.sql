-- Supabase schema for Aurora MVP (Postgres + pgvector)
-- Run this in your Supabase SQL editor or psql against the DB.

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector; -- pgvector

-- ------------------------------------------------------------------
-- Knowledge base (RAG) documents
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS knowledge_docs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    content text NOT NULL,
    source text,
    created_at timestamptz DEFAULT now(),
    embedding vector(384)
);

-- ivfflat index for fast nearest-neighbor search (adjust lists as needed)
CREATE INDEX IF NOT EXISTS idx_knowledge_embedding_ivfflat ON knowledge_docs USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- RPC helper: match_knowledge_docs(query_embedding, match_threshold, match_count)
-- Expects the caller to pass an array of float (embedding) via SQL array
CREATE OR REPLACE FUNCTION match_knowledge_docs(query_embedding vector, match_threshold float DEFAULT 0.0, match_count int DEFAULT 5)
RETURNS TABLE(id uuid, title text, content text, similarity float) AS $$
BEGIN
  RETURN QUERY
  SELECT k.id, k.title, k.content, 1 - (k.embedding <=> query_embedding) AS similarity
  FROM knowledge_docs k
  WHERE k.embedding IS NOT NULL
  ORDER BY k.embedding <-> query_embedding
  LIMIT match_count;
END;
$$ LANGUAGE plpgsql STABLE;


-- ------------------------------------------------------------------
-- Users / Profiles
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name text,
    email text,
    avatar_url text,
    total_xp int DEFAULT 0,
    karma int DEFAULT 0,
    level int DEFAULT 1,
    notification_token text, -- optional push token
    created_at timestamptz DEFAULT now()
);


-- ------------------------------------------------------------------
-- Grows (AI plans)
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS grows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    name text,
    strain_name text,
    strain_type text,
    medium text,
    light_type text,
    light_wattage int,
    space_width_cm int,
    space_length_cm int,
    space_height_cm int,
    start_date timestamptz,
    estimated_end_date timestamptz,
    current_phase text,
    status text,
    ai_plan jsonb,
    created_at timestamptz DEFAULT now()
);


-- ------------------------------------------------------------------
-- Grow snapshots (sensor readings tied to a grow)
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS grow_snapshots (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    grow_id uuid REFERENCES grows(id) ON DELETE CASCADE,
    recorded_at timestamptz DEFAULT now(),
    temperature numeric,
    humidity numeric,
    ph numeric,
    ec numeric,
    vpd numeric,
    notes text
);


-- ------------------------------------------------------------------
-- Social: posts, likes, comments
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS posts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    content text,
    image_urls text[],
    strain_tag text,
    grow_id uuid REFERENCES grows(id),
    day_number int,
    likes_count int DEFAULT 0,
    comments_count int DEFAULT 0,
    is_toxic boolean DEFAULT false,
    is_hidden boolean DEFAULT false,
    tech_score numeric,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS post_likes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS post_comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    content text,
    is_toxic boolean DEFAULT false,
    is_hidden boolean DEFAULT false,
    is_flagged boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- RPC to increment/decrement counters (atomic)
CREATE OR REPLACE FUNCTION increment_likes(post_id_param uuid)
RETURNS void AS $$
BEGIN
  UPDATE posts SET likes_count = COALESCE(likes_count, 0) + 1 WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_likes(post_id_param uuid)
RETURNS void AS $$
BEGIN
  UPDATE posts SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0) WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_comments(post_id_param uuid)
RETURNS void AS $$
BEGIN
  UPDATE posts SET comments_count = COALESCE(comments_count, 0) + 1 WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------------
-- Chat messages and summaries
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    role text,
    content text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chat_summaries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    summary text,
    message_count int,
    created_at timestamptz DEFAULT now()
);


-- ------------------------------------------------------------------
-- Notifications, daily tasks, reports, gamification
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    type text,
    title text,
    body text,
    data jsonb,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS daily_tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    grow_id uuid REFERENCES grows(id) ON DELETE CASCADE,
    title text,
    description text,
    due_date date,
    is_completed boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS reports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    reason text,
    post_id uuid REFERENCES posts(id),
    comment_id uuid REFERENCES post_comments(id),
    status text DEFAULT 'pending',
    created_at timestamptz DEFAULT now()
);

-- ------------------------------------------------------------------
-- Indexes to improve query performance
-- ------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_grows_user ON grows(user_id);
CREATE INDEX IF NOT EXISTS idx_snapshots_grow ON grow_snapshots(grow_id, recorded_at DESC);

-- End of schema
