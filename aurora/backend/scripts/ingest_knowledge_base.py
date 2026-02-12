"""
📁 backend/scripts/ingest_knowledge_base.py
Reads all .md files from backend/knowledge_base/, splits them into chunks,
generates embeddings via sentence-transformers, and upserts into Supabase
pgvector tables (knowledge_documents + knowledge_embeddings).

Usage:
  cd backend
  python -m scripts.ingest_knowledge_base
"""

import hashlib
import logging
import os
import re
import sys
import time
from pathlib import Path
from typing import List

from dotenv import load_dotenv

# ── Load environment ────────────────────────────────────────────
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("ingest")

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    logger.error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in .env")
    sys.exit(1)


# ── Text chunking ──────────────────────────────────────────────

def estimate_tokens(text: str) -> int:
    """Rough token estimate: 1 token ≈ 4 chars for English/Spanish."""
    return len(text) // 4


def chunk_markdown(
    text: str,
    max_tokens: int = 500,
    overlap_tokens: int = 50,
) -> List[str]:
    """
    Split markdown text into chunks of approximately `max_tokens` tokens.
    Splits on heading boundaries (## / ###) first, then on paragraphs,
    then on sentence boundaries if needed.
    """
    max_chars = max_tokens * 4
    overlap_chars = overlap_tokens * 4

    # Split on headings (keep the heading with the content after it)
    sections = re.split(r"(?=\n## |\n### )", text)
    sections = [s.strip() for s in sections if s.strip()]

    chunks: List[str] = []
    current_chunk = ""

    for section in sections:
        # If adding this section exceeds the limit, flush current chunk
        if current_chunk and len(current_chunk) + len(section) + 2 > max_chars:
            chunks.append(current_chunk.strip())
            # Keep overlap from end of current chunk
            current_chunk = current_chunk[-overlap_chars:] if len(current_chunk) > overlap_chars else ""

        # If the section itself is too large, split by paragraphs
        if len(section) > max_chars:
            paragraphs = section.split("\n\n")
            for para in paragraphs:
                if len(current_chunk) + len(para) + 2 > max_chars:
                    if current_chunk:
                        chunks.append(current_chunk.strip())
                        current_chunk = current_chunk[-overlap_chars:] if len(current_chunk) > overlap_chars else ""
                    # If single paragraph is still too long, split by sentences
                    if len(para) > max_chars:
                        sentences = re.split(r"(?<=[.!?])\s+", para)
                        for sentence in sentences:
                            if len(current_chunk) + len(sentence) + 1 > max_chars:
                                if current_chunk:
                                    chunks.append(current_chunk.strip())
                                    current_chunk = current_chunk[-overlap_chars:] if len(current_chunk) > overlap_chars else ""
                            current_chunk += " " + sentence if current_chunk else sentence
                    else:
                        current_chunk += "\n\n" + para if current_chunk else para
                else:
                    current_chunk += "\n\n" + para if current_chunk else para
        else:
            current_chunk += "\n\n" + section if current_chunk else section

    if current_chunk.strip():
        chunks.append(current_chunk.strip())

    return chunks


def content_hash(text: str) -> str:
    """Generate a stable hash for deduplication."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


# ── Main ingestion logic ──────────────────────────────────────

def main():
    from supabase import create_client
    from sentence_transformers import SentenceTransformer

    logger.info("🚀 Starting knowledge base ingestion")

    # Connect to Supabase
    sb = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    logger.info("✅ Supabase connected")

    # Load embedding model
    logger.info("⏳ Loading embedding model (all-MiniLM-L6-v2)...")
    model = SentenceTransformer("all-MiniLM-L6-v2")
    logger.info("✅ Embedding model loaded (384 dimensions)")

    # Find knowledge base directory
    kb_dir = Path(__file__).resolve().parent.parent / "knowledge_base"
    if not kb_dir.exists():
        logger.error("Knowledge base directory not found: %s", kb_dir)
        sys.exit(1)

    md_files = sorted(kb_dir.glob("*.md"))
    if not md_files:
        logger.error("No .md files found in %s", kb_dir)
        sys.exit(1)

    logger.info("📂 Found %d documents in %s", len(md_files), kb_dir)

    total_chunks = 0
    total_documents = 0

    for md_file in md_files:
        file_name = md_file.stem  # e.g. "nutricion_cannabis"
        title = file_name.replace("_", " ").title()
        content = md_file.read_text(encoding="utf-8")
        doc_hash = content_hash(content)

        logger.info("──────────────────────────────────────")
        logger.info("📄 Processing: %s (%d chars)", md_file.name, len(content))

        # ── Upsert document ────────────────────────────────
        # Check if document already exists
        existing = (
            sb.table("knowledge_documents")
            .select("id, content_hash")
            .eq("source_file", md_file.name)
            .execute()
        )

        doc_id = None
        if existing.data:
            doc_id = existing.data[0]["id"]
            existing_hash = existing.data[0].get("content_hash", "")

            if existing_hash == doc_hash:
                logger.info("⏭️  Skipping (unchanged): %s", md_file.name)
                continue

            # Update existing document
            sb.table("knowledge_documents").update({
                "title": title,
                "content": content,
                "content_hash": doc_hash,
            }).eq("id", doc_id).execute()
            logger.info("🔄 Updated document: %s (id=%s)", title, doc_id)

            # Delete old embeddings for this document
            sb.table("knowledge_embeddings").delete().eq(
                "document_id", doc_id
            ).execute()
            logger.info("🗑️  Cleared old embeddings for document %s", doc_id)
        else:
            # Insert new document
            result = sb.table("knowledge_documents").insert({
                "title": title,
                "source_file": md_file.name,
                "content": content,
                "content_hash": doc_hash,
            }).execute()
            doc_id = result.data[0]["id"]
            logger.info("➕ Inserted document: %s (id=%s)", title, doc_id)

        total_documents += 1

        # ── Chunk and embed ────────────────────────────────
        chunks = chunk_markdown(content, max_tokens=500, overlap_tokens=50)
        logger.info("   Chunks: %d", len(chunks))

        for i, chunk_text in enumerate(chunks):
            # Generate embedding
            embedding = model.encode(chunk_text, normalize_embeddings=True)
            embedding_list = embedding.tolist()

            # Insert embedding
            sb.table("knowledge_embeddings").insert({
                "document_id": doc_id,
                "chunk_index": i,
                "content": chunk_text,
                "embedding": embedding_list,
            }).execute()

            token_estimate = estimate_tokens(chunk_text)
            logger.info(
                "   ✅ Chunk %d/%d embedded (%d tokens, %d chars)",
                i + 1, len(chunks), token_estimate, len(chunk_text),
            )

        total_chunks += len(chunks)

    logger.info("══════════════════════════════════════")
    logger.info(
        "🎉 Ingestion complete: %d documents, %d chunks embedded",
        total_documents, total_chunks,
    )
    logger.info("══════════════════════════════════════")


if __name__ == "__main__":
    main()
