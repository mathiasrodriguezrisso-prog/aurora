-- ============================================
-- AURORA DATABASE SCHEMA
-- Supabase PostgreSQL Migration
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================
-- 1. PROFILES (extends auth.users)
-- ============================================
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    level INTEGER DEFAULT 1,
    xp INTEGER DEFAULT 0,
    karma INTEGER DEFAULT 0,
    is_pro BOOLEAN DEFAULT FALSE,
    preferred_language TEXT DEFAULT 'en',
    total_grows INTEGER DEFAULT 0,
    notification_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_profiles_username ON public.profiles USING btree (username);
CREATE INDEX idx_profiles_level ON public.profiles USING btree (level);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Trigger for updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url, username)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url',
        'user_' || substr(NEW.id::text, 1, 8)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 2. STRAINS (Reference data)
-- ============================================
CREATE TYPE strain_type AS ENUM ('sativa', 'indica', 'hybrid', 'ruderalis');
CREATE TYPE difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced');

CREATE TABLE public.strains (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    breeder TEXT,
    type strain_type DEFAULT 'hybrid',
    thc_min DECIMAL(4,2),
    thc_max DECIMAL(4,2),
    cbd_min DECIMAL(4,2),
    cbd_max DECIMAL(4,2),
    flowering_weeks_min INTEGER,
    flowering_weeks_max INTEGER,
    difficulty difficulty_level DEFAULT 'intermediate',
    description TEXT,
    effects TEXT[],
    flavors TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_strains_name ON public.strains USING gin (name gin_trgm_ops);
CREATE INDEX idx_strains_type ON public.strains USING btree (type);

-- RLS (public read)
ALTER TABLE public.strains ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Strains are viewable by everyone" ON public.strains
    FOR SELECT USING (true);

-- ============================================
-- 3. GROWS
-- ============================================
CREATE TYPE grow_seed_type AS ENUM ('regular', 'feminized', 'auto');
CREATE TYPE grow_medium AS ENUM ('soil', 'coco', 'hydro', 'aero');
CREATE TYPE grow_phase AS ENUM ('germination', 'seedling', 'vegetative', 'flowering', 'harvest', 'drying', 'curing');
CREATE TYPE grow_status AS ENUM ('active', 'completed', 'abandoned');

CREATE TABLE public.grows (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    strain_name TEXT,
    strain_id UUID REFERENCES public.strains(id),
    strain_type grow_seed_type DEFAULT 'feminized',
    medium grow_medium DEFAULT 'soil',
    light_type TEXT,
    light_wattage INTEGER,
    space_width_cm INTEGER,
    space_length_cm INTEGER,
    space_height_cm INTEGER,
    start_date DATE DEFAULT CURRENT_DATE,
    estimated_end_date DATE,
    actual_end_date DATE,
    current_phase grow_phase DEFAULT 'germination',
    status grow_status DEFAULT 'active',
    ai_plan JSONB,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_grows_user_id ON public.grows USING btree (user_id);
CREATE INDEX idx_grows_status ON public.grows USING btree (status);
CREATE INDEX idx_grows_current_phase ON public.grows USING btree (current_phase);

-- RLS
ALTER TABLE public.grows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own grows" ON public.grows
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own grows" ON public.grows
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own grows" ON public.grows
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own grows" ON public.grows
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger
CREATE TRIGGER update_grows_updated_at
    BEFORE UPDATE ON public.grows
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 4. PLANTS
-- ============================================
CREATE TYPE plant_status AS ENUM ('healthy', 'stressed', 'sick', 'dead', 'harvested');

CREATE TABLE public.plants (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    grow_id UUID REFERENCES public.grows(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    position TEXT,
    status plant_status DEFAULT 'healthy',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_plants_grow_id ON public.plants USING btree (grow_id);

-- RLS
ALTER TABLE public.plants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage plants in own grows" ON public.plants
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.grows
            WHERE grows.id = plants.grow_id
            AND grows.user_id = auth.uid()
        )
    );

-- ============================================
-- 5. GROW SNAPSHOTS (Sensor/Manual readings)
-- ============================================
CREATE TABLE public.grow_snapshots (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    grow_id UUID REFERENCES public.grows(id) ON DELETE CASCADE NOT NULL,
    temperature DECIMAL(4,1),
    humidity DECIMAL(4,1),
    vpd DECIMAL(4,2),
    ph DECIMAL(3,1),
    ec DECIMAL(4,2),
    co2_ppm INTEGER,
    light_hours INTEGER,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_grow_snapshots_grow_id ON public.grow_snapshots USING btree (grow_id);
CREATE INDEX idx_grow_snapshots_recorded_at ON public.grow_snapshots USING btree (recorded_at);

-- RLS
ALTER TABLE public.grow_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage snapshots in own grows" ON public.grow_snapshots
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.grows
            WHERE grows.id = grow_snapshots.grow_id
            AND grows.user_id = auth.uid()
        )
    );

-- ============================================
-- 6. GROW EVENTS
-- ============================================
CREATE TYPE event_type AS ENUM (
    'watering', 'feeding', 'training', 'defoliation',
    'transplant', 'photo', 'note', 'phase_change', 'harvest'
);

CREATE TABLE public.grow_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    grow_id UUID REFERENCES public.grows(id) ON DELETE CASCADE NOT NULL,
    plant_id UUID REFERENCES public.plants(id) ON DELETE SET NULL,
    event_type event_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    scheduled_date DATE,
    completed_at TIMESTAMP WITH TIME ZONE,
    is_ai_generated BOOLEAN DEFAULT FALSE,
    metadata JSONB,
    image_urls TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_grow_events_grow_id ON public.grow_events USING btree (grow_id);
CREATE INDEX idx_grow_events_scheduled_date ON public.grow_events USING btree (scheduled_date);
CREATE INDEX idx_grow_events_event_type ON public.grow_events USING btree (event_type);

-- RLS
ALTER TABLE public.grow_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage events in own grows" ON public.grow_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.grows
            WHERE grows.id = grow_events.grow_id
            AND grows.user_id = auth.uid()
        )
    );

-- ============================================
-- 7. POSTS (Social Feed)
-- ============================================
CREATE TYPE post_classification AS ENUM ('showcase', 'question', 'tutorial', 'other');

CREATE TABLE public.posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    grow_id UUID REFERENCES public.grows(id) ON DELETE SET NULL,
    content TEXT,
    image_urls TEXT[],
    tech_score DECIMAL(3,2) DEFAULT 0,
    classification post_classification DEFAULT 'other',
    grow_snapshot_id UUID REFERENCES public.grow_snapshots(id) ON DELETE SET NULL,
    is_visible BOOLEAN DEFAULT TRUE,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_posts_user_id ON public.posts USING btree (user_id);
CREATE INDEX idx_posts_created_at ON public.posts USING btree (created_at DESC);
CREATE INDEX idx_posts_tech_score ON public.posts USING btree (tech_score DESC);
CREATE INDEX idx_posts_is_visible ON public.posts USING btree (is_visible) WHERE is_visible = TRUE;

-- RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Visible posts are viewable by everyone" ON public.posts
    FOR SELECT USING (is_visible = TRUE);
CREATE POLICY "Users can insert own posts" ON public.posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON public.posts
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON public.posts
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 8. COMMENTS
-- ============================================
CREATE TABLE public.comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    is_visible BOOLEAN DEFAULT TRUE,
    toxicity_score DECIMAL(3,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_comments_post_id ON public.comments USING btree (post_id);
CREATE INDEX idx_comments_user_id ON public.comments USING btree (user_id);

-- RLS
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Visible comments are viewable by everyone" ON public.comments
    FOR SELECT USING (is_visible = TRUE);
CREATE POLICY "Users can insert own comments" ON public.comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON public.comments
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON public.comments
    FOR DELETE USING (auth.uid() = user_id);

-- Function to update comments count
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_comment_change
    AFTER INSERT OR DELETE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- ============================================
-- 9. LIKES
-- ============================================
CREATE TABLE public.likes (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

-- Indexes
CREATE INDEX idx_likes_post_id ON public.likes USING btree (post_id);

-- RLS
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Likes are viewable by everyone" ON public.likes
    FOR SELECT USING (true);
CREATE POLICY "Users can insert own likes" ON public.likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own likes" ON public.likes
    FOR DELETE USING (auth.uid() = user_id);

-- Function to update likes count
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_like_change
    AFTER INSERT OR DELETE ON public.likes
    FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- ============================================
-- 10. CHAT MESSAGES (Dr. Aurora)
-- ============================================
CREATE TYPE chat_role AS ENUM ('user', 'assistant', 'system');

CREATE TABLE public.chat_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    role chat_role NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_messages_user_id ON public.chat_messages USING btree (user_id);
CREATE INDEX idx_chat_messages_created_at ON public.chat_messages USING btree (created_at);

-- RLS
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own chat messages" ON public.chat_messages
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 11. CHAT SUMMARIES
-- ============================================
CREATE TABLE public.chat_summaries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    summary TEXT NOT NULL,
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_summaries_user_id ON public.chat_summaries USING btree (user_id);

-- RLS
ALTER TABLE public.chat_summaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own chat summaries" ON public.chat_summaries
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 12. NOTIFICATIONS
-- ============================================
CREATE TYPE notification_type AS ENUM ('task', 'alert', 'social', 'system');

CREATE TABLE public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    type notification_type NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications USING btree (is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created_at ON public.notifications USING btree (created_at DESC);

-- RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own notifications" ON public.notifications
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 13. ACHIEVEMENTS
-- ============================================
CREATE TABLE public.achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    icon_url TEXT,
    xp_reward INTEGER DEFAULT 0,
    criteria JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Achievements are viewable by everyone" ON public.achievements
    FOR SELECT USING (true);

-- ============================================
-- 14. USER ACHIEVEMENTS
-- ============================================
CREATE TABLE public.user_achievements (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    achievement_id UUID REFERENCES public.achievements(id) ON DELETE CASCADE NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, achievement_id)
);

-- Indexes
CREATE INDEX idx_user_achievements_user_id ON public.user_achievements USING btree (user_id);

-- RLS
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User achievements are viewable by everyone" ON public.user_achievements
    FOR SELECT USING (true);
CREATE POLICY "System can insert user achievements" ON public.user_achievements
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 15. KNOWLEDGE DOCS (RAG)
-- ============================================
CREATE TABLE public.knowledge_docs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT,
    embedding VECTOR(768),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for vector similarity search
CREATE INDEX idx_knowledge_docs_embedding ON public.knowledge_docs
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- RLS
ALTER TABLE public.knowledge_docs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Knowledge docs are viewable by authenticated users" ON public.knowledge_docs
    FOR SELECT USING (auth.role() = 'authenticated');

-- Function to search knowledge docs
CREATE OR REPLACE FUNCTION match_knowledge_docs(
    query_embedding VECTOR(768),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 5
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        kd.id,
        kd.title,
        kd.content,
        1 - (kd.embedding <=> query_embedding) AS similarity
    FROM public.knowledge_docs kd
    WHERE 1 - (kd.embedding <=> query_embedding) > match_threshold
    ORDER BY kd.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- ============================================
-- ENABLE REALTIME
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
