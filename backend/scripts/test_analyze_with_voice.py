"""
用本地 王家卫.mp3 + image.jpg 测试 POST /api/analyze_with_voice。
需先启动服务: cd backend && uvicorn main:app --reload
在 backend 目录执行: python scripts/test_analyze_with_voice.py
"""
import base64
import json
import sys
from pathlib import Path

import httpx

_backend = Path(__file__).resolve().parent.parent
AUDIO_FILE = _backend / "王家卫.mp3"
IMAGE_FILE = _backend / "image.jpg"
BASE_URL = "http://127.0.0.1:8000"
OUTPUT_FILE = _backend / "tts_output.mp3"

def main():
    if not AUDIO_FILE.exists():
        print(f"未找到 {AUDIO_FILE}")
        sys.exit(1)
    if not IMAGE_FILE.exists():
        print(f"未找到 {IMAGE_FILE}")
        sys.exit(1)

    audio_b64 = base64.b64encode(AUDIO_FILE.read_bytes()).decode()
    image_b64 = base64.b64encode(IMAGE_FILE.read_bytes()).decode()
    print(f"音频: {AUDIO_FILE.name} ({len(audio_b64)} base64 字符)")
    print(f"图片: {IMAGE_FILE.name} ({len(image_b64)} base64 字符)")
    print(f"请求 {BASE_URL}/api/analyze_with_voice ...")

    try:
        resp = httpx.post(
            f"{BASE_URL}/api/analyze_with_voice",
            json={
                "audio_base64": audio_b64,
                "image_base64": image_b64,
                "audio_media_type": "audio/mpeg",
            },
            timeout=120.0,
        )
        resp.raise_for_status()
        data = resp.json()
        b64 = data.get("voice_guide_audio_base64")
        if not b64:
            print("响应中无 voice_guide_audio_base64")
            sys.exit(1)
        raw = base64.b64decode(b64)
        OUTPUT_FILE.write_bytes(raw)
        print(f"已保存: {OUTPUT_FILE} ({len(raw)} 字节)")
        print("\n响应:")
        print(json.dumps(data, ensure_ascii=False, indent=2))
        if "voice_guide" in data:
            print("\nvoice_guide:", data["voice_guide"])
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
