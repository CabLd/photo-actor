"""
测试 POST /api/tts 文本转语音，将返回的 Base64 音频保存为 mp3 文件。
需先启动服务: cd backend && uvicorn main:app --reload
在 backend 目录执行: python scripts/test_tts.py
"""
import base64
import sys
from pathlib import Path

import httpx

_backend = Path(__file__).resolve().parent.parent
BASE_URL = "http://127.0.0.1:8000"
OUTPUT_FILE = _backend / "tts_output.mp3"

# 中文女声（Elevenlabs 普通话）：Julia=标准女声, Maya=温柔, ShanShan=活泼
DEFAULT_VOICE_ID = "GgmlugwQ4LYXBbEXENWm"  # Julia - 标准普通话女声


def main():
    body = {
        "text": "靠近点，让电线分割画面。",
        "voice_id": DEFAULT_VOICE_ID,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.5,
            "speed": 0.88,
            "style": 0.0,
            "use_speaker_boost": True,
        },
        "language_code": "zh",
    }
    print(f"请求 {BASE_URL}/api/tts ...")
    print(f"文本: {body['text']!r}")

    try:
        resp = httpx.post(
            f"{BASE_URL}/api/tts",
            json=body,
            timeout=60.0,
        )
        resp.raise_for_status()
        data = resp.json()
        b64 = data.get("audio_base64")
        if not b64:
            print("响应中无 audio_base64")
            sys.exit(1)
        raw = base64.b64decode(b64)
        OUTPUT_FILE.write_bytes(raw)
        print(f"已保存: {OUTPUT_FILE} ({len(raw)} 字节)")
    except httpx.ConnectError:
        print("连接失败，请先启动: cd backend && uvicorn main:app --reload")
        sys.exit(1)
    except Exception as e:
        print("失败:", e)
        if hasattr(e, "response") and e.response is not None:
            print("响应体:", e.response.text[:500])
        sys.exit(1)


if __name__ == "__main__":
    main()
