"""
Aurora Embeddings Service
Document processing and embedding generation for RAG.
"""
import logging
from typing import List, Tuple
from pathlib import Path
import re

logger = logging.getLogger(__name__)


class EmbeddingsService:
    """Service for processing documents and generating embeddings."""
    
    CHUNK_SIZE = 500  # Characters per chunk
    CHUNK_OVERLAP = 50  # Overlap between chunks
    
    def __init__(self):
        """Initialize embeddings service."""
        self._model = None
    
    def _get_model(self):
        """Lazy load the embedding model."""
        if self._model is None:
            from sentence_transformers import SentenceTransformer
            self._model = SentenceTransformer('all-MiniLM-L6-v2')
            logger.info("Loaded embedding model: all-MiniLM-L6-v2")
        return self._model
    
    def chunk_document(self, content: str, title: str = "") -> List[Tuple[str, str]]:
        """
        Split document into chunks with overlap.
        
        Args:
            content: Full document content
            title: Document title/filename
            
        Returns:
            List of (chunk_title, chunk_content) tuples
        """
        chunks = []
        
        # Split by sections first (## headers)
        sections = re.split(r'\n##\s+', content)
        
        for i, section in enumerate(sections):
            if not section.strip():
                continue
            
            # Get section title from first line
            lines = section.strip().split('\n')
            section_title = lines[0].strip().replace('#', '').strip() if lines else ""
            section_content = '\n'.join(lines[1:]) if len(lines) > 1 else lines[0]
            
            # Build full title
            if title and section_title:
                full_title = f"{title} - {section_title}"
            elif title:
                full_title = title
            else:
                full_title = section_title or f"Section {i+1}"
            
            # If section is small enough, keep as single chunk
            if len(section_content) <= self.CHUNK_SIZE:
                chunks.append((full_title, section_content.strip()))
                continue
            
            # Split large sections into overlapping chunks
            text = section_content.strip()
            start = 0
            chunk_num = 1
            
            while start < len(text):
                end = start + self.CHUNK_SIZE
                
                # Try to break at paragraph or sentence boundary
                if end < len(text):
                    # Look for paragraph break
                    para_break = text.rfind('\n\n', start, end)
                    if para_break > start + self.CHUNK_SIZE // 2:
                        end = para_break
                    else:
                        # Look for sentence break
                        sentence_break = max(
                            text.rfind('. ', start, end),
                            text.rfind('.\n', start, end),
                            text.rfind(':\n', start, end)
                        )
                        if sentence_break > start + self.CHUNK_SIZE // 2:
                            end = sentence_break + 1
                
                chunk_content = text[start:end].strip()
                if chunk_content:
                    chunk_title = f"{full_title} (Part {chunk_num})" if chunk_num > 1 else full_title
                    chunks.append((chunk_title, chunk_content))
                    chunk_num += 1
                
                start = end - self.CHUNK_OVERLAP
                if start < 0:
                    start = 0
                
                # Prevent infinite loop
                if start >= len(text) - 10:
                    break
        
        logger.info(f"Split document into {len(chunks)} chunks")
        return chunks
    
    def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding vector for text."""
        model = self._get_model()
        # Truncate if necessary (model max is ~256 tokens)
        text = text[:2000]
        embedding = model.encode(text, normalize_embeddings=True)
        return embedding.tolist()
    
    def process_document(self, content: str, title: str) -> List[dict]:
        """
        Process a document into chunks with embeddings.
        
        Args:
            content: Document content
            title: Document title
            
        Returns:
            List of dicts with title, content, embedding
        """
        chunks = self.chunk_document(content, title)
        
        processed = []
        for chunk_title, chunk_content in chunks:
            # Combine title and content for embedding
            embed_text = f"{chunk_title}\n\n{chunk_content}"
            embedding = self.generate_embedding(embed_text)
            
            processed.append({
                'title': chunk_title,
                'content': chunk_content,
                'embedding': embedding
            })
        
        return processed
    
    def process_markdown_file(self, filepath: Path) -> List[dict]:
        """Process a markdown file into chunks with embeddings."""
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract title from first # header or filename
        title_match = re.match(r'^#\s+(.+)$', content, re.MULTILINE)
        if title_match:
            title = title_match.group(1).strip()
        else:
            title = filepath.stem.replace('_', ' ').title()
        
        return self.process_document(content, title)
