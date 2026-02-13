"""Request/response schemas and JSON Schema for CharaBoard response_format."""
from pydantic import BaseModel, Field


# ----- API request (our /api/analyze) -----


class AnalyzeRequest(BaseModel):
    """POST /api/analyze body."""

    image_base64: str = Field(..., description="JPEG image as base64 string")
    intent: str = Field(..., description="User shooting intent, e.g. 赛博朋克风格的雨夜街景")


# ----- API response (our /api/analyze) + CharaBoard json_schema -----


class AnalysisBlock(BaseModel):
    light_direction: str = Field(..., description="光线方向描述")
    subject_mood: str = Field(..., description="主体情绪/氛围")
    composition_tip: str = Field(..., description="构图建议")


class ShaderBlock(BaseModel):
    brightness: float = Field(..., ge=-1.0, le=1.0)
    saturation: float = Field(..., ge=0.0, le=2.0)
    contrast: float = Field(..., ge=-1.0, le=1.0)
    tintR: float = Field(..., ge=0.5, le=1.5)
    tintG: float = Field(..., ge=0.5, le=1.5)
    tintB: float = Field(..., ge=0.5, le=1.5)
    warmth: float = Field(..., ge=0.0, le=1.0)
    vignette: float = Field(..., ge=0.0, le=1.0)


class DirectorResponse(BaseModel):
    """Exact shape returned by AI and by our /api/analyze."""

    analysis: AnalysisBlock
    shader: ShaderBlock
    voice_guide: str = Field(..., max_length=15)
    ready_to_capture: bool


# ----- JSON Schema for CharaBoard response_format (json_schema type) -----
# Used to force the model to return this structure.


def get_director_response_json_schema() -> dict:
    """Schema for response_format.json_schema so the model returns DirectorResponse."""
    return {
        "type": "object",
        "properties": {
            "analysis": {
                "type": "object",
                "properties": {
                    "light_direction": {"type": "string", "description": "光线方向描述"},
                    "subject_mood": {"type": "string", "description": "主体情绪/氛围"},
                    "composition_tip": {"type": "string", "description": "构图建议"},
                },
                "required": ["light_direction", "subject_mood", "composition_tip"],
            },
            "shader": {
                "type": "object",
                "properties": {
                    "brightness": {"type": "number", "description": "亮度 -1.0~1.0"},
                    "saturation": {"type": "number", "description": "饱和度 0~2.0"},
                    "contrast": {"type": "number", "description": "对比度 -1.0~1.0"},
                    "tintR": {"type": "number", "description": "红色通道 0.5~1.5"},
                    "tintG": {"type": "number", "description": "绿色通道 0.5~1.5"},
                    "tintB": {"type": "number", "description": "蓝色通道 0.5~1.5"},
                    "warmth": {"type": "number", "description": "暖色 0~1.0"},
                    "vignette": {"type": "number", "description": "暗角 0~1.0"},
                },
                "required": [
                    "brightness",
                    "saturation",
                    "contrast",
                    "tintR",
                    "tintG",
                    "tintB",
                    "warmth",
                    "vignette",
                ],
            },
            "voice_guide": {
                "type": "string",
                "description": "15字以内导演语音指导",
                "maxLength": 15,
            },
            "ready_to_capture": {
                "type": "boolean",
                "description": "是否建议用户此时拍摄",
            },
        },
        "required": ["analysis", "shader", "voice_guide", "ready_to_capture"],
    }
