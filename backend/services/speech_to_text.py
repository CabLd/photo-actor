"""Speech-to-text via CharaBoard 文件转录 API (POST /elevenlabs/stt/convert)."""
import base64
import io
import json
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

# 扩展名 -> multipart 用的 MIME（m4a 用 mp4）
_MIME = {"mp3": "audio/mpeg", "m4a": "audio/mp4", "mp4": "audio/mp4", "wav": "audio/wav", "webm": "audio/webm"}


def transcribe_audio(audio_base64: str, audio_media_type: str | None = None) -> str:
    """
    解码 Base64 音频，调用 CharaBoard 文件转录接口，返回识别文本。
    认证：Authorization Bearer + x-app-id + x-platform-id；请求：multipart/form-data。
    """
    raw = base64.b64decode(
        audio_base64.strip().split(",")[-1] if "," in audio_base64 else audio_base64
    )
    ext = "m4a"
    if audio_media_type:
        _m = audio_media_type.lower()
        if "mp3" in _m or "mpeg" in _m:
            ext = "mp3"
        elif "wav" in _m:
            ext = "wav"
        elif "webm" in _m:
            ext = "webm"
        elif "mp4" in _m or "m4a" in _m:
            ext = "m4a"
    filename = f"audio.{ext}"
    mime = _MIME.get(ext, "audio/mp4")

    base = CHARABOARD_VOICE_BASE_URL.rstrip("/")
    url = f"{base}/elevenlabs/stt/convert"

    headers = {
        "Authorization": f"Bearer {CHARABOARD_API_KEY}",
        "x-app-id": str(X_APP_ID),
        "x-platform-id": str(X_PLATFORM_ID),
    }

    with httpx.Client(timeout=30.0) as client:
        files = {"file": (filename, io.BytesIO(raw), mime)}
        data = {
            "model_id": "scribe_v2",
            "language_code": "zh",
            "timestamps_granularity": "word",
            "diarize": "true",
        }
        t0 = time.perf_counter()
        resp = client.post(url, headers=headers, files=files, data=data)
        logger.info("CharaBoard STT convert latency_seconds=%.3f", time.perf_counter() - t0)
        if resp.status_code >= 400:
            logger.warning("CharaBoard STT %s body: %s", resp.status_code, resp.text[:500])
            resp.raise_for_status()

    body = resp.text.strip()
    if not body:
        return ""

    try:
        out = json.loads(body)
        if isinstance(out, dict) and "text" in out:
            return (out["text"] or "").strip()
        if isinstance(out, dict) and "transcript" in out:
            return (out["transcript"] or "").strip()
        if isinstance(out, str):
            return out.strip()
    except json.JSONDecodeError:
        pass
    return body.strip()
