"""
Phase 1.1: FastAPI 中继 + CharaBoard 多模态调用与延迟测试.

启动: 在 backend 目录下
  export CHARABOARD_API_KEY=your-api-key
  uvicorn main:app --reload

真机/其他机器访问本机服务时，必须加 --host 0.0.0.0，否则只监听 127.0.0.1 收不到请求：
  uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""
import base64
import logging
import time
from concurrent.futures import TimeoutError as FuturesTimeoutError, ThreadPoolExecutor

from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware

from config import CHARABOARD_API_KEY, MOCK_ANALYZE_WITH_VOICE_RESPONSE, ANALYZE_WITH_VOICE_TIMEOUT_SECONDS
from schemas import (
    AnalyzeRequest,
    AnalyzeWithVoiceRequest,
    AnalyzeWithVoiceResponse,
    DirectorResponse,
    TranscribeRequest,
    TranscribeResponse,
    TtsRequest,
    TtsResponse,
)
from services.charaboard_client import analyze_frame
from services.speech_to_text import transcribe_audio
from services.text_to_speech import text_to_speech, VOICE_ID_ZH_FEMALE

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
    """has_api_key=false 时 /api/analyze 与 /api/transcribe 会返回 503。"""
    return {
        "status": "ok",
        "has_api_key": bool(CHARABOARD_API_KEY),
        "message": "Set CHARABOARD_API_KEY in backend/.env if you get 503 on /api/transcribe or /api/analyze",
    }


@app.post("/api/analyze", response_model=DirectorResponse)
def analyze(req: AnalyzeRequest, response: Response):
    """
    接收 Base64 图片和用户意图，调用 CharaBoard 多模态，返回严格 JSON：
    analysis, shader, voice_guide, ready_to_capture.
    响应头 X-Response-Time-Seconds 为本次推理耗时（秒），用于 Phase 1.1 延迟测试。
    """
    if not CHARABOARD_API_KEY:
        logger.warning("CHARABOARD_API_KEY not set -> 503")
        raise HTTPException(
            status_code=503,
            detail="CHARABOARD_API_KEY not set. Add it to backend/.env and restart uvicorn.",
        )
    t0 = time.perf_counter()
    try:
        director, elapsed = analyze_frame(req.image_base64, req.intent)
        total = time.perf_counter() - t0
        logger.info("/api/analyze CharaBoard=%.3fs total=%.3fs intent=%s", elapsed, total, req.intent[:50])
        response.headers["X-Response-Time-Seconds"] = f"{elapsed:.3f}"
        return director
    except Exception as e:
        logger.exception("analyze failed: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@app.post("/api/transcribe", response_model=TranscribeResponse)
def transcribe(req: TranscribeRequest):
    """
    语音转文字：接收 Base64 音频，调用 CharaBoard 文件转录 API（elevenlabs/stt/convert），返回识别文本。
    使用与 /api/analyze 相同的 CHARABOARD_API_KEY。
    """
    if not CHARABOARD_API_KEY:
        logger.warning("CHARABOARD_API_KEY not set -> 503")
        raise HTTPException(
            status_code=503,
            detail="CHARABOARD_API_KEY not set. Add it to backend/.env and restart uvicorn.",
        )
    t0 = time.perf_counter()
    try:
        text = transcribe_audio(req.audio_base64, req.audio_media_type)
        total = time.perf_counter() - t0
        logger.info("/api/transcribe total=%.3fs", total)
        return TranscribeResponse(text=text)
    except Exception as e:
        logger.exception("transcribe failed: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@app.post("/api/tts", response_model=TtsResponse)
def tts(req: TtsRequest):
    """
    文本转语音（非流式）：调用 CharaBoard Elevenlabs TTS，返回 Base64 音频。
    使用与 /api/transcribe 相同的 CHARABOARD_API_KEY。
    """
    if not CHARABOARD_API_KEY:
        logger.warning("CHARABOARD_API_KEY not set -> 503")
        raise HTTPException(
            status_code=503,
            detail="CHARABOARD_API_KEY not set. Add it to backend/.env and restart uvicorn.",
        )
    t0 = time.perf_counter()
    try:
        voice_settings = req.voice_settings.model_dump() if req.voice_settings else None
        audio_bytes, content_type = text_to_speech(
            text=req.text,
            voice_id=req.voice_id,
            model_id=req.model_id,
            voice_settings=voice_settings,
            language_code=req.language_code,
        )
        audio_b64 = base64.b64encode(audio_bytes).decode()
        total = time.perf_counter() - t0
        logger.info("/api/tts total=%.3fs text_len=%d", total, len(req.text))
        return TtsResponse(audio_base64=audio_b64, content_type=content_type)
    except Exception as e:
        logger.exception("tts failed: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


def _do_analyze_with_voice(req: AnalyzeWithVoiceRequest) -> AnalyzeWithVoiceResponse:
    """内部：转写 -> 分析 -> TTS。在子线程中执行，主线程通过 future.result(timeout) 计时。"""
    text = transcribe_audio(req.audio_base64, req.audio_media_type)
    director, _ = analyze_frame(req.image_base64, text or "")

    voice_guide_audio_b64 = ""
    voice_guide_audio_content_type = "audio/mpeg"
    if director.voice_guide and director.voice_guide.strip():
        try:
            audio_bytes, content_type = text_to_speech(
                director.voice_guide.strip(),
                voice_id=VOICE_ID_ZH_FEMALE,
                model_id="eleven_multilingual_v2",
                language_code="zh",
            )
            voice_guide_audio_b64 = base64.b64encode(audio_bytes).decode()
            voice_guide_audio_content_type = content_type
        except Exception as e:
            logger.warning("analyze_with_voice TTS voice_guide failed: %s", e)

    return AnalyzeWithVoiceResponse(
        **director.model_dump(),
        voice_guide_audio_base64=voice_guide_audio_b64,
        voice_guide_audio_content_type=voice_guide_audio_content_type,
    )


@app.post("/api/analyze_with_voice", response_model=AnalyzeWithVoiceResponse)
def analyze_with_voice(req: AnalyzeWithVoiceRequest, response: Response):
    """
    接收语音+图片：先转写再分析并 TTS。请求过程中计时，若 10s 内未完成则终止等待、直接返回王家卫风格 mock。
    """
    if not CHARABOARD_API_KEY:
        logger.warning("CHARABOARD_API_KEY not set -> 503")
        raise HTTPException(
            status_code=503,
            detail="CHARABOARD_API_KEY not set. Add it to backend/.env and restart uvicorn.",
        )
    t0 = time.perf_counter()
    deadline = t0 + ANALYZE_WITH_VOICE_TIMEOUT_SECONDS
    poll_interval = 0.5
    executor = ThreadPoolExecutor(max_workers=1)
    try:
        future = executor.submit(_do_analyze_with_voice, req)
        while True:
            now = time.perf_counter()
            if now >= deadline:
                executor.shutdown(wait=False)  # 不等待子线程，否则 return 后 with 会阻塞到线程结束
                total = now - t0
                logger.warning(
                    "/api/analyze_with_voice 计时到 %.1fs 分析未结束，终止等待并返回 mock",
                    total,
                )
                response.headers["X-Response-Time-Seconds"] = f"{total:.3f}"
                response.headers["X-Response-Mock"] = "true"
                return MOCK_ANALYZE_WITH_VOICE_RESPONSE
            try:
                result = future.result(timeout=poll_interval)
                break
            except FuturesTimeoutError:
                continue
        executor.shutdown(wait=False)
        total = time.perf_counter() - t0
        logger.info("/api/analyze_with_voice total=%.3fs (real)", total)
        response.headers["X-Response-Time-Seconds"] = f"{total:.3f}"
        return result
    except Exception as e:
        executor.shutdown(wait=False)
        logger.exception("analyze_with_voice failed: %s", e)
        raise HTTPException(status_code=502, detail=str(e))
