"""
📁 backend/app/routers/media.py
Media upload router — image upload, validation, optimization, and storage.
"""

import asyncio
import logging
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, Form, status

from app.dependencies import get_supabase_client, get_current_user_id
from app.services.image_service import ImageService

logger = logging.getLogger("aurora.media")

router = APIRouter(prefix="/media", tags=["Media"])

ALLOWED_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


# ── Single Upload ──────────────────────────────────────────────

@router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_image(
    file: UploadFile = File(...),
    bucket: str = Form("post-images"),
    grow_id: Optional[str] = Form(None),
    user_id: str = Depends(get_current_user_id),
):
    """
    Upload a single image.
    - Validates file type (jpg, jpeg, png, webp) and size (max 10MB).
    - Strips EXIF metadata for privacy.
    - Optimizes/compresses the image.
    - Uploads to Supabase Storage.
    - Returns the public URL.
    """
    # Validate content type
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={
                "error": f"Invalid file type: {file.content_type}. "
                         f"Allowed: {', '.join(ALLOWED_TYPES)}"
            },
        )

    # Read file and validate size
    file_bytes = await file.read()
    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={
                "error": f"File too large: {len(file_bytes) / 1024 / 1024:.1f}MB. "
                         f"Maximum: {MAX_FILE_SIZE / 1024 / 1024:.0f}MB"
            },
        )

    try:
        # Process image: strip EXIF + optimize
        processed_bytes = await asyncio.to_thread(
            ImageService.process_image, file_bytes
        )

        # Generate unique filename
        ext = "webp"  # Always output as webp for best compression
        unique_name = f"{user_id[:8]}/{uuid.uuid4().hex}.{ext}"

        # Upload to Supabase Storage
        sb = get_supabase_client()
        await asyncio.to_thread(
            sb.storage.from_(bucket).upload,
            unique_name,
            processed_bytes,
            {"content-type": "image/webp"},
        )

        # Get public URL
        public_url = sb.storage.from_(bucket).get_public_url(unique_name)

        logger.info(
            "✅ Image uploaded: %s (%d KB → %d KB)",
            unique_name,
            len(file_bytes) // 1024,
            len(processed_bytes) // 1024,
        )

        return {
            "url": public_url,
            "bucket": bucket,
            "path": unique_name,
            "original_size": len(file_bytes),
            "optimized_size": len(processed_bytes),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Upload error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Multiple Upload ────────────────────────────────────────────

@router.post("/upload-multiple", status_code=status.HTTP_201_CREATED)
async def upload_multiple_images(
    files: list[UploadFile] = File(...),
    bucket: str = Form("post-images"),
    grow_id: Optional[str] = Form(None),
    user_id: str = Depends(get_current_user_id),
):
    """
    Upload up to 5 images at once.
    Each image is validated, processed, and uploaded individually.
    Returns a list of URLs for successfully uploaded images.
    """
    if len(files) > 5:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"error": "Maximum 5 images per upload"},
        )

    if len(files) == 0:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"error": "No files provided"},
        )

    results = []
    errors = []

    for i, file in enumerate(files):
        try:
            # Validate type
            if file.content_type not in ALLOWED_TYPES:
                errors.append({
                    "index": i,
                    "filename": file.filename,
                    "error": f"Invalid type: {file.content_type}",
                })
                continue

            # Read and validate size
            file_bytes = await file.read()
            if len(file_bytes) > MAX_FILE_SIZE:
                errors.append({
                    "index": i,
                    "filename": file.filename,
                    "error": f"File too large: {len(file_bytes) / 1024 / 1024:.1f}MB",
                })
                continue

            # Process
            processed_bytes = await asyncio.to_thread(
                ImageService.process_image, file_bytes
            )

            # Upload
            ext = "webp"
            unique_name = f"{user_id[:8]}/{uuid.uuid4().hex}.{ext}"
            sb = get_supabase_client()

            await asyncio.to_thread(
                sb.storage.from_(bucket).upload,
                unique_name,
                processed_bytes,
                {"content-type": "image/webp"},
            )

            public_url = sb.storage.from_(bucket).get_public_url(unique_name)

            results.append({
                "url": public_url,
                "bucket": bucket,
                "path": unique_name,
                "original_size": len(file_bytes),
                "optimized_size": len(processed_bytes),
            })

        except Exception as e:
            errors.append({
                "index": i,
                "filename": file.filename or f"file_{i}",
                "error": str(e),
            })

    logger.info(
        "✅ Multi-upload: %d succeeded, %d failed",
        len(results), len(errors),
    )

    return {
        "uploaded": results,
        "errors": errors,
        "total_uploaded": len(results),
        "total_errors": len(errors),
    }
