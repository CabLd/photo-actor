"""
用当前目录下的 sample.mp3 测试语音转文字，直接调用 CharaBoard 接口。
在 backend 目录执行: python scripts/test_transcribe.py
"""
import base64
import sys
from pathlib import Path

# 保证 backend 在 path 里
_backend = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_backend))

from config import CHARABOARD_API_KEY
from services.speech_to_text import transcribe_audio


def main():
    sample = _backend / "王家卫.mp3"
    if not sample.exists():
        print(f"未找到 {sample}，请在该目录放置 sample.mp3")
        sys.exit(1)
    if not CHARABOARD_API_KEY:
        print("请设置 CHARABOARD_API_KEY（backend/.env 或 export）")
        sys.exit(1)

    raw = sample.read_bytes()
    b64 = base64.b64encode(raw).decode()
    print(f"音频大小: {len(raw)} 字节，正在调用 CharaBoard STT...")

    try:
        text = transcribe_audio(b64, "audio/mpeg")
        print("识别结果:", repr(text))
    except Exception as e:
        print("失败:", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
