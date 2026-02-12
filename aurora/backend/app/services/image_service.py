"""
📁 backend/app/services/image_service.py
Image processing service — EXIF stripping, optimization, thumbnails,
and Supabase Storage upload.
"""

import io
import logging
import uuid
from typing import Optional

from PIL import Image, ExifTags

from app.dependencies import get_supabase_client

logger = logging.getLogger("aurora.images")


class ImageService:
    """Handles image processing and upload for the Aurora app."""

    BUCKET_NAME = "aurora-images"
    MAX_WIDTH = 1920
    MAX_HEIGHT = 1920
    THUMB_SIZE = (300, 300)
    QUALITY = 85

    @staticmethod
    def strip_exif(image: Image.Image) -> Image.Image:
        """Remove all EXIF metadata from an image for privacy."""
        data = list(image.getdata())
        clean_image = Image.new(image.mode, image.size)
        clean_image.putdata(data)
        return clean_image

    @staticmethod
    def optimize_image(
        image_bytes: bytes,
        max_width: int = 1920,
        max_height: int = 1920,
        quality: int = 85,
    ) -> bytes:
        """Resize and optimize an image, stripping EXIF data."""
        image = Image.open(io.BytesIO(image_bytes))

        # Convert to RGB if necessary
        if image.mode in ("RGBA", "P"):
            image = image.convert("RGB")

        # Strip EXIF
        image = ImageService.strip_exif(image)

        # Resize maintaining aspect ratio
        image.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)

        # Save optimized
        output = io.BytesIO()
        image.save(output, format="JPEG", quality=quality, optimize=True)
        output.seek(0)

        return output.getvalue()

    @staticmethod
    def create_thumbnail(image_bytes: bytes, size: tuple = (300, 300)) -> bytes:
        """Create a thumbnail from an image."""
        image = Image.open(io.BytesIO(image_bytes))

        if image.mode in ("RGBA", "P"):
            image = image.convert("RGB")

        image = ImageService.strip_exif(image)
        image.thumbnail(size, Image.Resampling.LANCZOS)

        output = io.BytesIO()
        image.save(output, format="JPEG", quality=80, optimize=True)
        output.seek(0)

        return output.getvalue()

    @staticmethod
    async def upload_image(
        image_bytes: bytes,
        user_id: str,
        folder: str = "posts",
    ) -> dict:
        """
        Process and upload an image to Supabase Storage.
        Returns dict with 'url' and 'thumbnail_url'.
        """
        sb = get_supabase_client()
        file_id = str(uuid.uuid4())

        # Optimize full image
        optimized = ImageService.optimize_image(image_bytes)
        full_path = f"{folder}/{user_id}/{file_id}.jpg"

        # Create thumbnail
        thumbnail = ImageService.create_thumbnail(image_bytes)
        thumb_path = f"{folder}/{user_id}/thumb_{file_id}.jpg"

        try:
            # Upload full image
            sb.storage.from_(ImageService.BUCKET_NAME).upload(
                full_path,
                optimized,
                file_options={"content-type": "image/jpeg"},
            )

            # Upload thumbnail
            sb.storage.from_(ImageService.BUCKET_NAME).upload(
                thumb_path,
                thumbnail,
                file_options={"content-type": "image/jpeg"},
            )

            # Get public URLs
            full_url = sb.storage.from_(ImageService.BUCKET_NAME).get_public_url(full_path)
            thumb_url = sb.storage.from_(ImageService.BUCKET_NAME).get_public_url(thumb_path)

            logger.info(
                "Image uploaded: %s (%.1f KB → %.1f KB)",
                full_path,
                len(image_bytes) / 1024,
                len(optimized) / 1024,
            )

            return {
                "url": full_url,
                "thumbnail_url": thumb_url,
                "file_id": file_id,
                "size_bytes": len(optimized),
            }

        except Exception as e:
            logger.error("Upload failed: %s", e)
            raise
