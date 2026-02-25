"""Text-to-speech via CharaBoard Elevenlabs TTS API (POST /elevenlabs/tts/generate, 非流式)."""
import logging
import time

import httpx

from config import (
    CHARABOARD_API_KEY,
    CHARABOARD_VOICE_BASE_URL,
    X_APP_ID,
    X_PLATFORM_ID,
)

logger = logging.getLogger(__name__)


def _default_voice_settings() -> dict:
    return {
        "stability": 0.5,
        "similarity_boost": 0.5,
        "speed": 0.88,
        "style": 0.0,
        "use_speaker_boost": True,
    }


# Elevenlabs 中文女声（CharaBoard 若沿用相同 ID 则可用）
VOICE_ID_ZH_FEMALE = "tOuLUAIdXShmWH7PEUrU"  # Julia - 标准普通话女声


def text_to_speech(
    text: str,
    voice_id: str,
    model_id: str | None = None,
    voice_settings: dict | None = None,
    language_code: str | None = None,
) -> tuple[bytes, str]:
    """
    调用 CharaBoard TTS 非流式接口，返回 (音频二进制, content_type)。
    认证：Authorization Bearer + x-app-id + x-platform-id。
    """
    base = CHARABOARD_VOICE_BASE_URL.rstrip("/")
    url = f"{base}/elevenlabs/tts/generate"

    headers = {
        "Authorization": f"Bearer {CHARABOARD_API_KEY}",
        "Content-Type": "application/json",
        "x-app-id": str(X_APP_ID),
        "x-platform-id": str(X_PLATFORM_ID),
    }

    payload = {
        "text": text,
        "voice_id": VOICE_ID_ZH_FEMALE,
        "model_id": model_id or "eleven_multilingual_v2",
        "voice_settings": _default_voice_settings(),
    }
    if language_code:
        payload["language_code"] = language_code

    t0 = time.perf_counter()
    with httpx.Client(timeout=60.0) as client:
        resp = client.post(url, headers=headers, json=payload)
        logger.info("CharaBoard TTS generate latency_seconds=%.3f", time.perf_counter() - t0)
        resp.raise_for_status()

    content_type = resp.headers.get("content-type", "audio/mpeg")
    if "application/json" in content_type:
        try:
            data = resp.json()
            if "audio_base64" in data:
                import base64
                return base64.b64decode(data["audio_base64"]), "audio/mpeg"
        except Exception:
            pass
    return resp.content, content_type.split(";")[0].strip() or "audio/mpeg"
