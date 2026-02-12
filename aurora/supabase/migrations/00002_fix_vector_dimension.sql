-- ============================================
-- FIX: Change VECTOR dimension from 768 to 384
-- Model all-MiniLM-L6-v2 generates 384-dimension vectors
-- ============================================

-- Drop the existing function first (depends on VECTOR(768))
DROP FUNCTION IF EXISTS match_knowledge_docs(VECTOR(768), FLOAT, INT);

-- Alter the column dimension
ALTER TABLE public.knowledge_docs
    ALTER COLUMN embedding TYPE VECTOR(384);

-- Drop and recreate the IVFFlat index
DROP INDEX IF EXISTS idx_knowledge_docs_embedding;
CREATE INDEX idx_knowledge_docs_embedding ON public.knowledge_docs
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Recreate the match function with VECTOR(384)
CREATE OR REPLACE FUNCTION match_knowledge_docs(
    query_embedding VECTOR(384),
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
