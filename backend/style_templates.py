"""预设风格模板配置"""

from typing import TypedDict


class StyleTemplate(TypedDict):
    """单个风格模板"""

    id: str
    name: str
    description: str
    thumbnail: str  # 缩略图 URL 或路径
    shader: dict[str, float]
    tags: list[str]


# 10 个预设风格模板
STYLE_TEMPLATES: list[StyleTemplate] = [
    {
        "id": "vintage",
        "name": "复古风格",
        "description": "高对比度、温暖色调、低饱和度、轻微噪点，模仿老式相机效果",
        "thumbnail": "/assets/templates/vintage.jpg",
        "shader": {
            "brightness": -0.1,
            "saturation": 0.8,
            "contrast": -0.3,
            "tintR": 1.1,
            "tintG": 0.9,
            "tintB": 0.9,
            "warmth": 1.3,
            "vignette": 0.2,
            "noise": 0.4,
            "sharpness": 0.9,
            "blur": 0.1,
            "texture_strength": 0.3,
        },
        "tags": ["复古", "怀旧", "温暖", "胶片"],
    },
    {
        "id": "wong_kar_wai",
        "name": "王家卫风格",
        "description": "电影感、高对比度、冷色调、深沉阴影",
        "thumbnail": "/assets/templates/wong_kar_wai.jpg",
        "shader": {
            "brightness": 0.1,
            "saturation": 1.0,
            "contrast": 0.8,
            "tintR": 1.2,
            "tintG": 0.8,
            "tintB": 1.3,
            "warmth": 1.0,
            "vignette": 0.4,
            "noise": 0.2,
            "sharpness": 1.2,
            "blur": 0.0,
            "texture_strength": 0.4,
        },
        "tags": ["电影", "文艺", "冷色调", "深沉"],
    },
    {
        "id": "dreamy",
        "name": "梦幻风格",
        "description": "柔和光线、低对比度、轻微的色调渲染、模糊背景",
        "thumbnail": "/assets/templates/dreamy.jpg",
        "shader": {
            "brightness": 0.2,
            "saturation": 1.1,
            "contrast": -0.5,
            "tintR": 1.0,
            "tintG": 1.1,
            "tintB": 1.2,
            "warmth": 1.2,
            "vignette": 0.1,
            "noise": 0.1,
            "sharpness": 0.5,
            "blur": 0.6,
            "texture_strength": 0.2,
        },
        "tags": ["梦幻", "柔和", "朦胧", "浪漫"],
    },
    {
        "id": "modern_minimal",
        "name": "现代极简",
        "description": "高亮度、适中的饱和度和对比度，简洁而鲜明的色彩",
        "thumbnail": "/assets/templates/modern_minimal.jpg",
        "shader": {
            "brightness": 0.3,
            "saturation": 1.0,
            "contrast": 0.6,
            "tintR": 1.0,
            "tintG": 1.0,
            "tintB": 1.0,
            "warmth": 1.0,
            "vignette": 0.0,
            "noise": 0.0,
            "sharpness": 1.4,
            "blur": 0.0,
            "texture_strength": 0.0,
        },
        "tags": ["现代", "极简", "清晰", "明亮"],
    },
    {
        "id": "black_white",
        "name": "黑白风格",
        "description": "强对比度、零饱和度、极简黑白效果，突出阴影和光线",
        "thumbnail": "/assets/templates/black_white.jpg",
        "shader": {
            "brightness": 0.2,
            "saturation": 0.0,
            "contrast": 1.2,
            "tintR": 1.0,
            "tintG": 1.0,
            "tintB": 1.0,
            "warmth": 0.5,
            "vignette": 0.5,
            "noise": 0.3,
            "sharpness": 1.5,
            "blur": 0.0,
            "texture_strength": 0.0,
        },
        "tags": ["黑白", "经典", "艺术", "对比"],
    },
    {
        "id": "sunset",
        "name": "日落风格",
        "description": "增强温暖色调、红色和黄色调，模拟日落效果",
        "thumbnail": "/assets/templates/sunset.jpg",
        "shader": {
            "brightness": 0.0,
            "saturation": 1.4,
            "contrast": 0.5,
            "tintR": 1.3,
            "tintG": 0.9,
            "tintB": 0.7,
            "warmth": 1.4,
            "vignette": 0.3,
            "noise": 0.1,
            "sharpness": 1.1,
            "blur": 0.0,
            "texture_strength": 0.1,
        },
        "tags": ["日落", "温暖", "浪漫", "金色"],
    },
    {
        "id": "film",
        "name": "复古胶片",
        "description": "低对比度、轻微的噪点和纹理，模拟老胶片效果",
        "thumbnail": "/assets/templates/film.jpg",
        "shader": {
            "brightness": -0.2,
            "saturation": 0.8,
            "contrast": -0.2,
            "tintR": 1.0,
            "tintG": 1.0,
            "tintB": 0.9,
            "warmth": 1.2,
            "vignette": 0.5,
            "noise": 0.5,
            "sharpness": 0.6,
            "blur": 0.1,
            "texture_strength": 0.7,
        },
        "tags": ["胶片", "复古", "纹理", "颗粒"],
    },
    {
        "id": "urban_night",
        "name": "都市夜景",
        "description": "高对比度、冷色调，突出夜景的光线效果",
        "thumbnail": "/assets/templates/urban_night.jpg",
        "shader": {
            "brightness": 0.0,
            "saturation": 1.2,
            "contrast": 1.0,
            "tintR": 1.1,
            "tintG": 1.0,
            "tintB": 1.4,
            "warmth": 0.9,
            "vignette": 0.3,
            "noise": 0.0,
            "sharpness": 1.3,
            "blur": 0.0,
            "texture_strength": 0.2,
        },
        "tags": ["夜景", "都市", "冷色", "霓虹"],
    },
    {
        "id": "pastel",
        "name": "粉彩风格",
        "description": "柔和的色调和较低的对比度，适合轻松的氛围",
        "thumbnail": "/assets/templates/pastel.jpg",
        "shader": {
            "brightness": 0.4,
            "saturation": 0.9,
            "contrast": -0.2,
            "tintR": 1.2,
            "tintG": 1.3,
            "tintB": 1.2,
            "warmth": 1.1,
            "vignette": 0.1,
            "noise": 0.0,
            "sharpness": 0.7,
            "blur": 0.2,
            "texture_strength": 0.3,
        },
        "tags": ["粉彩", "少女", "柔和", "清新"],
    },
    {
        "id": "cool",
        "name": "冷酷风格",
        "description": "低饱和度、冷色调、强对比度，营造冷静的氛围",
        "thumbnail": "/assets/templates/cool.jpg",
        "shader": {
            "brightness": -0.1,
            "saturation": 0.7,
            "contrast": 1.1,
            "tintR": 0.9,
            "tintG": 1.0,
            "tintB": 1.3,
            "warmth": 0.7,
            "vignette": 0.4,
            "noise": 0.1,
            "sharpness": 1.2,
            "blur": 0.0,
            "texture_strength": 0.4,
        },
        "tags": ["冷酷", "冷色", "高级", "沉稳"],
    },
]


def get_all_templates() -> list[StyleTemplate]:
    """获取所有风格模板"""
    return STYLE_TEMPLATES


def get_template_by_id(template_id: str) -> StyleTemplate | None:
    """根据 ID 获取单个模板"""
    for template in STYLE_TEMPLATES:
        if template["id"] == template_id:
            return template
    return None


def search_templates_by_tag(tag: str) -> list[StyleTemplate]:
    """根据标签搜索模板"""
    return [t for t in STYLE_TEMPLATES if tag in t["tags"]]
