from fastapi import APIRouter, Depends
from supabase import Client
from app.dependencies import get_supabase
from app.config import settings

router = APIRouter()


@router.get("/health")
async def health_check():
    """Basic health check endpoint."""
    return {
        "status": "healthy",
        "environment": settings.environment,
    }


@router.get("/health/db")
async def database_health(supabase: Client = Depends(get_supabase)):
    """Database connectivity health check."""
    try:
        # Simple query to check database connection
        result = supabase.table("profiles").select("id").limit(1).execute()
        return {
            "status": "healthy",
            "database": "connected",
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e),
        }
