"""
Aurora RAG Service
Retrieval Augmented Generation using pgvector for semantic search.
"""
import asyncio
import logging
from typing import List
from dataclasses import dataclass

from supabase import Client

logger = logging.getLogger(__name__)


@dataclass
class RetrievedDocument:
    """A document retrieved from the knowledge base."""

    id: str
    title: str
    content: str
    similarity: float


class RAGService:
    """Service for Retrieval Augmented Generation."""

    def __init__(self, supabase_client: Client):
        """Initialize RAG service with Supabase client."""
        self.supabase = supabase_client
        self._embedding_model = None

    def _get_embedding_model(self):
        """Lazy load the embedding model (all-MiniLM-L6-v2 → 384 dims)."""
        if self._embedding_model is None:
            from sentence_transformers import SentenceTransformer
            self._embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
            logger.info("Loaded embedding model: all-MiniLM-L6-v2 (384 dims)")
        return self._embedding_model

    def _generate_embedding(self, text: str) -> List[float]:
        """Generate embedding vector for text. Synchronous."""
        model = self._get_embedding_model()
        text = text[:8000]  # Truncate long text
        embedding = model.encode(text, normalize_embeddings=True)
        return embedding.tolist()

    async def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding vector for text. Thread-safe async wrapper."""
        return await asyncio.to_thread(self._generate_embedding, text)

    async def search_knowledge(
        self,
        query: str,
        match_threshold: float = 0.5,
        match_count: int = 5,
    ) -> List[RetrievedDocument]:
        """
        Search knowledge base using semantic similarity.

        Args:
            query: Search query text.
            match_threshold: Minimum similarity threshold (0-1).
            match_count: Maximum number of results.

        Returns:
            List of matching documents with similarity scores.
        """
        try:
            # Generate embedding (sync model, runs in thread)
            query_embedding = await self.generate_embedding(query)

            params = {
                "query_embedding": query_embedding,
                "match_threshold": match_threshold,
                "match_count": match_count,
            }

            # Supabase-py is synchronous — wrap in to_thread
            result = await asyncio.to_thread(
                lambda: self.supabase.rpc(
                    "match_knowledge_docs", params
                ).execute()
            )

            if not result.data:
                logger.warning(
                    "No documents found for query: %s…", query[:50]
                )
                return []

            documents = [
                RetrievedDocument(
                    id=str(doc["id"]),
                    title=doc["title"],
                    content=doc["content"],
                    similarity=float(doc["similarity"]),
                )
                for doc in result.data
            ]

            logger.info("Retrieved %d documents for query", len(documents))
            return documents

        except Exception as e:
            logger.error("Error searching knowledge base: %s", e)
            return []

    def build_context(
        self,
        documents: List[RetrievedDocument],
        max_tokens: int = 3000,
    ) -> str:
        """
        Build context string from retrieved documents.

        Args:
            documents: List of retrieved documents.
            max_tokens: Approximate maximum tokens (chars / 4).

        Returns:
            Formatted context string.
        """
        if not documents:
            return ""

        sorted_docs = sorted(
            documents, key=lambda d: d.similarity, reverse=True
        )

        context_parts: list[str] = []
        current_length = 0
        max_chars = max_tokens * 4

        for doc in sorted_docs:
            doc_text = f"### {doc.title}\n{doc.content}\n"
            if current_length + len(doc_text) > max_chars:
                break
            context_parts.append(doc_text)
            current_length += len(doc_text)

        return "\n".join(context_parts)

    async def get_relevant_context(
        self,
        strain_name: str,
        medium: str,
        experience_level: str,
        seed_type: str,
    ) -> str:
        """
        Get relevant context for grow plan generation.

        Args:
            strain_name: Name of the strain.
            medium: Growing medium.
            experience_level: Grower's experience.
            seed_type: Type of seed.

        Returns:
            Combined context from multiple queries.
        """
        queries = [
            f"cannabis cultivation {strain_name} growing guide",
            f"cannabis {medium} growing techniques nutrients schedule",
            f"cannabis growth phases germination vegetative flowering",
            f"cannabis VPD temperature humidity optimal ranges",
            f"cannabis common problems pests diseases deficiencies",
        ]

        if experience_level == "beginner":
            queries.append("beginner cannabis growing tips common mistakes")

        if seed_type == "auto":
            queries.append("autoflower cannabis light schedule feeding")

        all_documents: List[RetrievedDocument] = []
        seen_ids: set[str] = set()

        for query in queries:
            docs = await self.search_knowledge(
                query=query,
                match_threshold=0.4,
                match_count=3,
            )
            for doc in docs:
                if doc.id not in seen_ids:
                    all_documents.append(doc)
                    seen_ids.add(doc.id)

        context = self.build_context(all_documents, max_tokens=4000)

        if not context:
            logger.warning("No relevant context found, using fallback")
            context = self._get_fallback_context()

        return context

    @staticmethod
    def _get_fallback_context() -> str:
        """Return fallback context if no documents are found."""
        return """
### Cannabis Growth Phases
- Germination: 3-7 days, keep seeds warm and moist
- Seedling: 2-3 weeks, low nutrients, high humidity
- Vegetative: 4-8 weeks (photos), 18/6 light, high nitrogen
- Flowering: 8-12 weeks, 12/12 light, high phosphorus/potassium
- Harvest: Check trichomes, 70% cloudy/30% amber
- Drying: 7-14 days, 60°F, 60% humidity
- Curing: 2-8 weeks in jars, burp daily first week

### VPD Ranges
- Seedling: 0.4-0.8 kPa (75-85°F, 65-75% RH)
- Vegetative: 0.8-1.2 kPa (70-85°F, 55-70% RH)
- Flowering: 1.0-1.5 kPa (68-80°F, 45-55% RH)

### Nutrient Guidelines
- Seedlings: EC 0.4-0.8, pH 6.0-6.5
- Vegetative: EC 1.0-1.6, pH 5.8-6.5, high N
- Flowering: EC 1.2-2.0, pH 5.8-6.5, high P-K
        """.strip()
