"""CharaBoard V1 chat completions client with vision (image) + json_schema response."""
import json
import time
from typing import Any

import httpx

from config import (
    CHARABOARD_API_KEY,
    CHARABOARD_BASE_URL,
    GPT_TYPE,
    X_APP_ID,
    X_MAX_TIME,
    X_PLATFORM_ID,
    X_QUALITY,
)
from schemas import DirectorResponse, get_director_response_json_schema


def _build_messages_with_image(image_base64: str, intent: str) -> list[dict[str, Any]]:
    """Build messages: system + user with image (OpenAI-style multimodal content)."""
    from prompts.photo_director import SYSTEM_PROMPT, build_user_message

    if not image_base64.strip().startswith("data:"):
        image_url = f"data:image/jpeg;base64,{image_base64.strip()}"
    else:
        image_url = image_base64.strip()

    text_part = build_user_message(intent)

    user_content = [
        {"type": "text", "text": text_part},
        {"type": "image_url", "image_url": {"url": image_url}},
    ]

    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_content},
    ]


def analyze_frame(image_base64: str, intent: str) -> tuple[DirectorResponse, float]:
    """
    Call CharaBoard chat completions with image + intent, return DirectorResponse and latency in seconds.
    Raises httpx.HTTPStatusError or ValueError on failure.
    """
    base = CHARABOARD_BASE_URL.rstrip("/")
    url = base if base.endswith("chat/completions") else f"{base}/chat/completions"
    headers = {
        "Authorization": f"Bearer {CHARABOARD_API_KEY}",
        "Content-Type": "application/json",
        "x-app-id": str(X_APP_ID),
        "x-platform-id": str(X_PLATFORM_ID),
        "x-max-time": str(X_MAX_TIME),
        "x-quality": X_QUALITY,
    }
    payload = {
        "gpt_type": GPT_TYPE,
        "messages": _build_messages_with_image(image_base64, intent),
        "stream": False,
        "max_tokens": 4096,
        "temperature": 0.5,
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "director_response",
                "description": "AI摄影导演分析结果与 Shader 参数",
                "schema": get_director_response_json_schema(),
            },
        },
    }

    start = time.perf_counter()
    with httpx.Client(timeout=float(X_MAX_TIME + 5)) as client:
        resp = client.post(url, headers=headers, json=payload)
        raw_text = resp.text
        resp.raise_for_status()
    elapsed = time.perf_counter() - start

    if not raw_text or not raw_text.strip():
        raise ValueError(
            f"CharaBoard returned empty body. status={resp.status_code}, url={url}"
        )

    try:
        data = json.loads(raw_text)
    except json.JSONDecodeError as e:
        raise ValueError(
            f"CharaBoard response is not valid JSON. "
            f"status={resp.status_code}, body_preview={raw_text[:500]!r}, error={e}"
        ) from e

    # 兼容 API 错误结构，如 {"error": {"message": "..."}}
    if "error" in data:
        err = data["error"]
        msg = err.get("message", str(err)) if isinstance(err, dict) else str(err)
        raise ValueError(f"CharaBoard API error: {msg}")

    content = (
        data.get("choices", [{}])[0]
        .get("message", {})
        .get("content")
    )
    if not content:
        raise ValueError(
            f"CharaBoard response has no choices[0].message.content. "
            f"Full response keys: {list(data.keys())}, "
            f"choices[0]: {data.get('choices', [{}])[0] if data.get('choices') else 'none'}"
        )

    # 模型可能返回被 ```json ... ``` 包裹的内容，先去掉代码块再解析
    content = content.strip()
    if content.startswith("```"):
        first = content.find("\n")
        if first != -1:
            content = content[first + 1 :]
        if content.endswith("```"):
            content = content[: content.rfind("```")].strip()

    try:
        parsed = json.loads(content)
    except json.JSONDecodeError as e:
        # 模型可能在 JSON 后附加说明文字，导致 "Extra data"；只解析前半段有效 JSON
        if "Extra data" in str(e) and hasattr(e, "pos") and e.pos:
            try:
                parsed = json.loads(content[: e.pos])
            except json.JSONDecodeError:
                raise ValueError(
                    f"CharaBoard message.content is not valid JSON. "
                    f"content_preview={content[:300]!r}, error={e}"
                ) from e
        else:
            raise ValueError(
                f"CharaBoard message.content is not valid JSON. "
                f"content_preview={content[:300]!r}, error={e}"
            ) from e

    # 模型可能返回超过 15 字的 voice_guide，截断以保证符合接口约定
    if "voice_guide" in parsed and isinstance(parsed["voice_guide"], str):
        parsed["voice_guide"] = parsed["voice_guide"][:15]

    # 模型可能返回超出范围的 shader 数值，clamp 到 schema 区间避免 ValidationError
    if "shader" in parsed and isinstance(parsed["shader"], dict):
        s = parsed["shader"]
        _clamp = lambda v, lo, hi: max(lo, min(hi, float(v))) if isinstance(v, (int, float)) else v
        s["brightness"] = _clamp(s.get("brightness", 0), -1.0, 1.0)
        s["saturation"] = _clamp(s.get("saturation", 1.0), 0.0, 2.0)
        s["contrast"] = _clamp(s.get("contrast", 1.0), -1.0, 1.0)
        s["tintR"] = _clamp(s.get("tintR", 1.0), 0.5, 1.5)
        s["tintG"] = _clamp(s.get("tintG", 1.0), 0.5, 1.5)
        s["tintB"] = _clamp(s.get("tintB", 1.0), 0.5, 1.5)
        s["warmth"] = _clamp(s.get("warmth", 0), 0.0, 1.0)
        s["vignette"] = _clamp(s.get("vignette", 0), 0.0, 1.0)

    director = DirectorResponse.model_validate(parsed)
    return director, elapsed
