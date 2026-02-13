"""
Phase 1.1: FastAPI 中继 + CharaBoard 多模态调用与延迟测试.

启动: 在 backend 目录下
  export CHARABOARD_API_KEY=your-api-key
  uvicorn main:app --reload

或从项目根目录:
  cd backend && uvicorn main:app --reload
"""
import logging

from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware

from config import CHARABOARD_API_KEY
from schemas import AnalyzeRequest, DirectorResponse
from services.charaboard_client import analyze_frame

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="AI Photo Director API",
    description="中继层：接收图片+意图，调用 CharaBoard 多模态，返回 Shader 参数与语音指导",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "has_api_key": bool(CHARABOARD_API_KEY)}


@app.post("/api/analyze", response_model=DirectorResponse)
def analyze(req: AnalyzeRequest, response: Response):
    """
    接收 Base64 图片和用户意图，调用 CharaBoard 多模态，返回严格 JSON：
    analysis, shader, voice_guide, ready_to_capture.
    响应头 X-Response-Time-Seconds 为本次推理耗时（秒），用于 Phase 1.1 延迟测试。
    """
    if not CHARABOARD_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="CHARABOARD_API_KEY not set",
        )
    try:
        director, elapsed = analyze_frame(req.image_base64, req.intent)
        logger.info("analyze latency_seconds=%.3f intent=%s", elapsed, req.intent[:50])
        response.headers["X-Response-Time-Seconds"] = f"{elapsed:.3f}"
        return director
    except Exception as e:
        logger.exception("analyze failed: %s", e)
        raise HTTPException(status_code=502, detail=str(e))
