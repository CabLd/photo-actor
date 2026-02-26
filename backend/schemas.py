"""Request/response schemas and JSON Schema for CharaBoard response_format."""
from pydantic import BaseModel, Field


# ----- API request (our /api/analyze) -----


class AnalyzeRequest(BaseModel):
    """POST /api/analyze body: image + text intent only."""

    image_base64: str = Field(..., description="JPEG image as base64 string")
    intent: str = Field(..., description="User shooting intent, e.g. 赛博朋克风格的雨夜街景")


# ----- POST /api/transcribe (voice to text) -----


class TranscribeRequest(BaseModel):
    """POST /api/transcribe body."""

    audio_base64: str = Field(..., description="Audio file as base64 string")
    audio_media_type: str | None = Field(default=None, description="e.g. audio/mpeg, audio/mp4; used as format hint")


class TranscribeResponse(BaseModel):
    """Response of /api/transcribe."""

    text: str = Field(..., description="Transcribed text")


# ----- POST /api/tts (text to speech) -----


class VoiceSettings(BaseModel):
    """Elevenlabs TTS voice_settings 对象，均为可选。"""

    stability: float = Field(default=0.5, ge=0.0, le=1.0, description="稳定性 0-1")
    similarity_boost: float = Field(default=0.75, ge=0.0, le=1.0, description="相似度增强 0-1")
    speed: float = Field(default=1.0, ge=0.7, le=1.2, description="语速 0.7-1.2")
    style: float = Field(default=0.0, ge=0.0, le=1.0, description="风格强度，仅 V2+ 模型")
    use_speaker_boost: bool = Field(default=True, description="说话者增强，仅 V2+ 模型")


class TtsRequest(BaseModel):
    """POST /api/tts body：文本转语音（非流式）。"""

    text: str = Field(..., description="要转换的文本")
    voice_id: str = Field(..., description="语音 ID，指定音色")
    model_id: str | None = Field(default="eleven_multilingual_v2", description="模型 ID")
    voice_settings: VoiceSettings | None = Field(default=None, description="语音设置")
    language_code: str | None = Field(default=None, description="语言代码，如 zh, en")


class TtsResponse(BaseModel):
    """TTS 响应：Base64 音频 + 内容类型。"""

    audio_base64: str = Field(..., description="音频 Base64")
    content_type: str = Field(default="audio/mpeg", description="如 audio/mpeg")


# ----- POST /api/analyze_with_voice (audio + image -> transcribe -> analyze) -----


class AnalyzeWithVoiceRequest(BaseModel):
    """POST /api/analyze_with_voice body: 语音 Base64 + 图片 Base64."""

    audio_base64: str = Field(..., description="Audio file as base64 string")
    image_base64: str = Field(..., description="JPEG image as base64 string")
    audio_media_type: str | None = Field(default=None, description="e.g. audio/mpeg, audio/mp4")


# ----- API response (our /api/analyze) + CharaBoard json_schema -----


class AnalysisBlock(BaseModel):
    light_direction: str = Field(..., description="光线方向描述")
    subject_mood: str = Field(..., description="主体情绪/氛围")
    composition_tip: str = Field(..., description="构图建议")


class ShaderBlock(BaseModel):
    brightness: float = Field(..., ge=-1.0, le=1.0)
    saturation: float = Field(..., ge=0.0, le=2.0)
    contrast: float = Field(..., ge=-1.0, le=1.0)
    tintR: float = Field(..., ge=0.5, le=2.0)
    tintG: float = Field(..., ge=0.5, le=2.0)
    tintB: float = Field(..., ge=0.5, le=2.0)
    warmth: float = Field(..., ge=0.0, le=2.0)
    vignette: float = Field(..., ge=0.0, le=1.0)
    noise: float = Field(..., ge=0.0, le=1.0)
    sharpness: float = Field(..., ge=0.0, le=2.0)
    blur: float = Field(..., ge=0.0, le=1.0)
    texture_strength: float = Field(..., ge=0.0, le=1.0)


# 姿势指导语义枚举，供 pose_guide 与客户端绘制使用
POSE_TYPE_VALUES = ("正面", "侧身", "微侧", "背身", "抬手", "无")
GAZE_DIRECTION_VALUES = ("正前", "左", "右", "左上", "左下", "右上", "右下", "无")


class PoseGuideBlock(BaseModel):
    """仅当有人且需要动作指导时输出；无人或不需要时省略或设为 null。"""

    pose_type: str = Field(default="无", description="姿势类型")
    gaze_direction: str = Field(default="无", description="视线方向")


class DirectorResponse(BaseModel):
    """Exact shape returned by AI and by our /api/analyze."""

    analysis: AnalysisBlock
    shader: ShaderBlock
    voice_guide: str = Field(..., max_length=300, description="1～3 句话；有人物时含姿势指导，无人则简短建议；用于 TTS")
    ready_to_capture: bool
    pose_guide: PoseGuideBlock | None = Field(default=None, description="姿势与视线语义，仅有人且需指导时返回")


class AnalyzeWithVoiceResponse(DirectorResponse):
    """POST /api/analyze_with_voice 响应：在 DirectorResponse 基础上增加 voice_guide 的 TTS 音频 Base64。"""

    voice_guide_audio_base64: str = Field(default="", description="voice_guide 文本转成的语音 Base64")
    voice_guide_audio_content_type: str = Field(default="audio/mpeg", description="音频 MIME 类型")


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
                    "noise": {"type": "number", "description": "噪点 0~1.0"},
                    "sharpness": {"type": "number", "description": "锐度 0~2.0"},
                    "blur": {"type": "number", "description": "模糊 0~1.0"},
                    "texture_strength": {"type": "number", "description": "纹理强度 0~1.0"},
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
                    "noise",
                    "sharpness",
                    "blur",
                    "texture_strength",
                ],
            },
            "voice_guide": {
                "type": "string",
                "description": "1～3 句话导演语音指导；有人物时含姿势指导，无人则简短建议",
                "maxLength": 300,
            },
            "ready_to_capture": {
                "type": "boolean",
                "description": "是否建议用户此时拍摄",
            },
            "pose_guide": {
                "type": "object",
                "description": "仅当有人且需要动作指导时输出；无人时省略或 null",
                "properties": {
                    "pose_type": {
                        "type": "string",
                        "enum": ["正面", "侧身", "微侧", "背身", "抬手", "无"],
                        "description": "姿势类型，无表示不给出姿势建议",
                    },
                    "gaze_direction": {
                        "type": "string",
                        "enum": ["正前", "左", "右", "左上", "左下", "右上", "右下", "无"],
                        "description": "视线方向",
                    },
                },
            },
        },
        "required": ["analysis", "shader", "voice_guide", "ready_to_capture"],
    }
