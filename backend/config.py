"""Backend config: API keys and CharaBoard settings from env."""
import os
from pathlib import Path

from dotenv import load_dotenv

# 固定从 config.py 所在目录（backend/）加载 .env，不依赖当前工作目录
_env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=_env_path)

# CharaBoard API (https://api-chat.charaboard.com)
CHARABOARD_API_KEY = os.getenv("CHARABOARD_API_KEY", "")
CHARABOARD_BASE_URL = os.getenv(
    "CHARABOARD_BASE_URL", "https://api-chat.charaboard.com/v2/"
)
# gpt_type: 8602 = MiniMax M2.1, 8204 = other; use vision-capable type if available
GPT_TYPE = int(os.getenv("GPT_TYPE", "8602"))
X_APP_ID = int(os.getenv("X_APP_ID", "4"))
X_PLATFORM_ID = int(os.getenv("X_PLATFORM_ID", "5"))

# Optional: timeout for chat completion (seconds)
X_MAX_TIME = int(os.getenv("X_MAX_TIME", "30"))

# 路由策略：speed=速度优先，cost=成本优先（CharaBoard x-quality）
X_QUALITY = os.getenv("X_QUALITY", "speed")
