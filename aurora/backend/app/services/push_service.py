"""
📁 backend/app/services/push_service.py
Push notification service — send FCM notifications to users
via Firebase Cloud Messaging HTTP v1 API.
"""

import json
import logging
from typing import Optional

import google.auth.transport.requests
from google.oauth2 import service_account
import httpx

from app.dependencies import get_supabase_client, get_settings

logger = logging.getLogger("aurora.push")

# ── FCM credentials ─────────────────────────────────────────

_credentials: Optional[service_account.Credentials] = None


def _get_access_token() -> str:
    """Get a fresh OAuth2 access token for FCM HTTP v1 API."""
    global _credentials
    settings = get_settings()

    if _credentials is None:
        _credentials = service_account.Credentials.from_service_account_file(
            settings.firebase_service_account_path,
            scopes=["https://www.googleapis.com/auth/firebase.messaging"],
        )

    _credentials.refresh(google.auth.transport.requests.Request())
    return _credentials.token


def _get_project_id() -> str:
    """Read project_id from service account JSON."""
    settings = get_settings()
    with open(settings.firebase_service_account_path) as f:
        data = json.load(f)
    return data["project_id"]


# ── Public API ───────────────────────────────────────────────


async def send_push_notification(
    user_id: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> bool:
    """
    Send a push notification to a specific user.

    1. Looks up the user's FCM token in the profiles table.
    2. If no token, logs a warning and returns False.
    3. Sends via FCM HTTP v1 API.
    4. Handles expired/invalid tokens.
    """
    sb = get_supabase_client()

    # 1. Look up FCM token
    try:
        result = (
            sb.table("profiles")
            .select("fcm_token")
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        fcm_token = result.data.get("fcm_token") if result.data else None
    except Exception as e:
        logger.error("Failed to fetch FCM token for user %s: %s", user_id, e)
        return False

    # 2. No token → warn and exit
    if not fcm_token:
        logger.warning("No FCM token for user %s — skipping push", user_id)
        return False

    # 3. Send via FCM
    try:
        access_token = _get_access_token()
        project_id = _get_project_id()
        url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"

        message = {
            "message": {
                "token": fcm_token,
                "notification": {
                    "title": title,
                    "body": body,
                },
                "android": {
                    "priority": "high",
                    "notification": {
                        "color": "#00E676",
                        "channel_id": "aurora_alerts",
                    },
                },
                "apns": {
                    "payload": {
                        "aps": {
                            "alert": {"title": title, "body": body},
                            "badge": 1,
                            "sound": "default",
                        }
                    }
                },
            }
        }

        # Attach custom data payload
        if data:
            message["message"]["data"] = {k: str(v) for k, v in data.items()}

        async with httpx.AsyncClient() as client:
            response = await client.post(
                url,
                json=message,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                timeout=10.0,
            )

        if response.status_code == 200:
            logger.info("Push sent to user %s", user_id)
            return True

        # 4. Handle errors
        error_body = response.json()
        error_code = (
            error_body.get("error", {})
            .get("details", [{}])[0]
            .get("errorCode", "")
        )

        if error_code in ("UNREGISTERED", "INVALID_ARGUMENT"):
            logger.warning(
                "Invalid/expired FCM token for user %s — clearing", user_id
            )
            sb.table("profiles").update({"fcm_token": None}).eq(
                "id", user_id
            ).execute()
            return False

        logger.error(
            "FCM error for user %s: %s %s",
            user_id,
            response.status_code,
            response.text,
        )
        return False

    except Exception as e:
        logger.error("Push notification failed for user %s: %s", user_id, e)
        return False


async def send_push_to_topic(
    topic: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> bool:
    """Send a push notification to all subscribers of a topic."""
    try:
        access_token = _get_access_token()
        project_id = _get_project_id()
        url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"

        message = {
            "message": {
                "topic": topic,
                "notification": {"title": title, "body": body},
                "data": {k: str(v) for k, v in (data or {}).items()},
            }
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                url,
                json=message,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                timeout=10.0,
            )

        if response.status_code == 200:
            logger.info("Push sent to topic %s", topic)
            return True

        logger.error("FCM topic error: %s %s", response.status_code, response.text)
        return False

    except Exception as e:
        logger.error("Topic push failed: %s", e)
        return False
