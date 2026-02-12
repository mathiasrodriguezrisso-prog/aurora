# Aurora Backend

Development notes and quick start for the Aurora backend.

Prerequisites

- Python 3.11
- Supabase project with service role key
- Groq API key

Quickstart

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements-dev.txt
cp .env.example .env
# edit .env with SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, GROQ_API_KEY
uvicorn app.main:app --reload
```

Ingest knowledge base

```powershell
python scripts/ingest_knowledge_base.py --dir ../knowledge_base
```

Run tests

```powershell
pytest -q
```
