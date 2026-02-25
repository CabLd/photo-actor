"""Backend config: API keys and CharaBoard settings from env."""
import os
from pathlib import Path

from dotenv import load_dotenv

from schemas import AnalysisBlock, AnalyzeWithVoiceResponse, ShaderBlock

# 固定从 config.py 所在目录（backend/）加载 .env，不依赖当前工作目录
_env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=_env_path)

# CharaBoard API (https://api-chat.charaboard.com)
CHARABOARD_API_KEY = os.getenv("CHARABOARD_API_KEY", "")
CHARABOARD_BASE_URL = os.getenv(
    "CHARABOARD_BASE_URL", "https://api-chat.charaboard.com/v2/"
)
# gpt_type: 8602 = MiniMax M2.1, 8204 = other; use vision-capable type if available
GPT_TYPE = int(os.getenv("GPT_TYPE", ""))
X_APP_ID = int(os.getenv("X_APP_ID", "4"))
X_PLATFORM_ID = int(os.getenv("X_PLATFORM_ID", "5"))

# Optional: timeout for chat completion (seconds)
X_MAX_TIME = int(os.getenv("X_MAX_TIME", "30"))

# 路由策略：speed=速度优先，cost=成本优先（CharaBoard x-quality）
X_QUALITY = os.getenv("X_QUALITY", "speed")

# 语音转文字（/api/transcribe）使用 CharaBoard 文件转录 API
CHARABOARD_VOICE_BASE_URL = os.getenv(
    "CHARABOARD_VOICE_BASE_URL", "https://api-voice.charaboard.com"
)

MOCK_ANALYZE_WITH_VOICE_RESPONSE = AnalyzeWithVoiceResponse(
    analysis=AnalysisBlock(
        light_direction="柔和的侧逆光，带一点霓虹色散",
        subject_mood="疏离、怀旧，像电影里的长镜头",
        composition_tip="留白多一点，人物偏一侧，更有氛围",
    ),
    shader=ShaderBlock(
        brightness=-0.08,
        saturation=0.92,
        contrast=1.0,
        tintR=1.05,
        tintG=0.98,
        tintB=0.92,
        warmth=0.35,
        vignette=0.45,
    ),
    voice_guide="再暗一点，更有氛围",
    ready_to_capture=False,
    voice_guide_audio_base64="",
    voice_guide_audio_content_type="audio/mpeg",
)

# 单位s
ANALYZE_WITH_VOICE_TIMEOUT_SECONDS = 5.0
