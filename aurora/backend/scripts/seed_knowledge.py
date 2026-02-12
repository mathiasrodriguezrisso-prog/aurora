#!/usr/bin/env python3
"""
Aurora Knowledge Base Seeder
Processes markdown documents and inserts them into Supabase pgvector.

Usage:
    python scripts/seed_knowledge.py
    
Requires:
    - SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env
    - knowledge/*.md files in backend directory
"""
import os
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from dotenv import load_dotenv
from supabase import create_client, Client

from app.services.embeddings_service import EmbeddingsService


def get_supabase_client() -> Client:
    """Create Supabase client from environment variables."""
    load_dotenv()
    
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    
    if not url or not key:
        raise ValueError(
            "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment"
        )
    
    return create_client(url, key)


def get_knowledge_files() -> list[Path]:
    """Get all markdown files from knowledge directory."""
    knowledge_dir = Path(__file__).parent.parent / 'knowledge'
    
    if not knowledge_dir.exists():
        raise FileNotFoundError(f"Knowledge directory not found: {knowledge_dir}")
    
    files = list(knowledge_dir.glob('*.md'))
    print(f"Found {len(files)} knowledge files")
    return files


def clear_existing_docs(supabase: Client):
    """Clear existing documents from knowledge_docs table."""
    print("Clearing existing knowledge documents...")
    try:
        supabase.table('knowledge_docs').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        print("Cleared existing documents")
    except Exception as e:
        print(f"Note: Could not clear existing docs (table may be empty): {e}")


def insert_documents(supabase: Client, documents: list[dict]):
    """Insert documents into Supabase knowledge_docs table."""
    print(f"Inserting {len(documents)} document chunks...")
    
    inserted = 0
    errors = 0
    
    for doc in documents:
        try:
            # Prepare data for insertion
            data = {
                'title': doc['title'][:255],  # Ensure title fits
                'content': doc['content'],
                'category': doc.get('category', 'general'),
                'embedding': doc['embedding']
            }
            
            supabase.table('knowledge_docs').insert(data).execute()
            inserted += 1
            
        except Exception as e:
            print(f"Error inserting document '{doc['title'][:50]}': {e}")
            errors += 1
    
    print(f"Inserted {inserted} documents, {errors} errors")
    return inserted, errors


def seed_knowledge_base():
    """Main function to seed the knowledge base."""
    print("=" * 50)
    print("Aurora Knowledge Base Seeder")
    print("=" * 50)
    
    # Initialize services
    supabase = get_supabase_client()
    embeddings = EmbeddingsService()
    
    # Get knowledge files
    files = get_knowledge_files()
    
    if not files:
        print("No knowledge files found!")
        return
    
    # Clear existing documents
    clear_existing_docs(supabase)
    
    # Process each file
    all_documents = []
    
    for filepath in files:
        print(f"\nProcessing: {filepath.name}")
        
        try:
            # Determine category from filename
            category = filepath.stem  # e.g., 'nutrition', 'phases', 'vpd'
            
            # Process file into chunks with embeddings
            chunks = embeddings.process_markdown_file(filepath)
            
            # Add category to each chunk
            for chunk in chunks:
                chunk['category'] = category
            
            all_documents.extend(chunks)
            print(f"  → Generated {len(chunks)} chunks")
            
        except Exception as e:
            print(f"  Error processing {filepath.name}: {e}")
    
    # Insert all documents
    print("\n" + "-" * 50)
    inserted, errors = insert_documents(supabase, all_documents)
    
    # Summary
    print("\n" + "=" * 50)
    print("Summary:")
    print(f"  Files processed: {len(files)}")
    print(f"  Total chunks: {len(all_documents)}")
    print(f"  Successfully inserted: {inserted}")
    print(f"  Errors: {errors}")
    print("=" * 50)


if __name__ == '__main__':
    seed_knowledge_base()
