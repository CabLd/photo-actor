"""Preset style template configuration"""

from typing import TypedDict


class StyleTemplate(TypedDict):
    """Single style template"""

    id: str
    name: str
    description: str
    thumbnail: str  # Thumbnail URL or path
    shader: dict[str, float]
    tags: list[str]


# 10 preset style templates
STYLE_TEMPLATES: list[StyleTemplate] = [
      {
        "id": "default_original",
        "name": "Original",
        "description": "Default original image, no processing applied",
        "thumbnail": "/assets/templates/vintage.jpg",
        "shader": {
            "brightness": 0.0,
            "saturation": 1.0,
            "contrast": 1.0,
            "tintR": 1.0,
            "tintG": 1.0,
            "tintB": 1.0,
            "warmth": 1.0,
            "vignette": 0.0,
            "noise": 0.0,
            "sharpness": 1.0,
            "blur": 0.0,
            "texture_strength": 0.0
        },
        "tags": ["original", "default", "neutral", "clean"],
    },
    {
        "id": "vintage",
        "name": "Vintage",
        "description": "High contrast, warm tones, low saturation, slight noise, mimicking old camera effects",
        "thumbnail": "/assets/templates/vintage.jpg",
        "shader": {
            "brightness": 0.05,
            "saturation": 0.85,
            "contrast": 1,
            "tintR": 1.12,
            "tintG": 1.05,
            "tintB": 0.92,
            "warmth": 1.35,
            "vignette": 0.45,
            "noise": 0.35,
            "sharpness": 0.75,
            "blur": 0.15,
            "texture_strength": 0.60
        },
        "tags": ["vintage", "retro", "warm", "film"],
    },
    {
        "id": "wong_kar_wai",
        "name": "Wong Kar-wai",
        "description": "Cinematic feel, high contrast, cool tones, deep shadows",
        "thumbnail": "/assets/templates/wong_kar_wai.jpg",
        "shader": {
            "brightness": -0.15,
            "saturation": 1.25,
            "contrast": 1,
            "tintR": 0.85,
            "tintG": 1.15,
            "tintB": 1.10,
            "warmth": 0.70,
            "vignette": 0.65,
            "noise": 0.15,
            "sharpness": 1.20,
            "blur": 0.05,
            "texture_strength": 0.40
        },
        "tags": ["cinematic", "artistic", "cool", "moody"],
    },
    {
        "id": "dreamy",
        "name": "Dreamy",
        "description": "Soft lighting, low contrast, subtle color grading, blurred background",
        "thumbnail": "/assets/templates/dreamy.jpg",
        "shader": {
           "brightness": 0.25,
            "saturation": 0.80,
            "contrast": 1,
            "tintR": 1.35,
            "tintG": 1.08,
            "tintB": 1.15,
            "warmth": 0.90,
            "vignette": 0.20,
            "noise": 0.05,
            "sharpness": 0.65,
            "blur": 0.40,
            "texture_strength": 0.10
        },
        "tags": ["dreamy", "soft", "hazy", "romantic"],
    },
    {
        "id": "modern_minimal",
        "name": "Modern Minimal",
        "description": "High brightness, moderate saturation and contrast, clean and vivid colors",
        "thumbnail": "/assets/templates/modern_minimal.jpg",
        "shader": {
            "brightness": 0.20,
            "saturation": 0.95,
            "contrast": 1,
            "tintR": 1.02,
            "tintG": 1.02,
            "tintB": 1.05,
            "warmth": 0.95,
            "vignette": 0.05,
            "noise": 0.00,
            "sharpness": 1.35,
            "blur": 0.00,
            "texture_strength": 0.00
        },
        "tags": ["modern", "minimal", "crisp", "bright"],
    },
    {
        "id": "black_white",
        "name": "Black & White",
        "description": "Strong contrast, zero saturation, minimalist black and white effect, emphasizing shadows and light",
        "thumbnail": "/assets/templates/black_white.jpg",
        "shader": {
            "brightness": -0.05,
            "saturation": 0.00,
            "contrast": 1,
            "tintR": 1.00,
            "tintG": 1.00,
            "tintB": 1.00,
            "warmth": 1.00,
            "vignette": 0.50,
            "noise": 0.25,
            "sharpness": 1.50,
            "blur": 0.00,
            "texture_strength": 0.45
        },
        "tags": ["black-white", "classic", "artistic", "contrast"],
    },
    {
        "id": "sunset",
        "name": "Sunset",
        "description": "Enhanced warm tones, red and yellow hues, simulating sunset effect",
        "thumbnail": "/assets/templates/sunset.jpg",
        "shader": {
            "brightness": 0.10,
            "saturation": 1.40,
            "contrast": 1,
            "tintR": 1.35,
            "tintG": 1.10,
            "tintB": 0.85,
            "warmth": 1.60,
            "vignette": 0.30,
            "noise": 0.05,
            "sharpness": 1.10,
            "blur": 0.15,
            "texture_strength": 0.20
        },
        "tags": ["sunset", "warm", "romantic", "golden"],
    },
    {
        "id": "film",
        "name": "Vintage Film",
        "description": "Low contrast, slight noise and texture, simulating old film effect",
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
        "tags": ["film", "vintage", "texture", "grain"],
    },
    {
        "id": "urban_night",
        "name": "Urban Night",
        "description": "High contrast, cool tones, emphasizing night scene lighting effects",
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
        "tags": ["night", "urban", "cool", "neon"],
    },
    {
        "id": "pastel",
        "name": "Pastel",
        "description": "Soft tones and lower contrast, suitable for relaxed atmosphere",
        "thumbnail": "/assets/templates/pastel.jpg",
        "shader": {
            "brightness": 0.35,
            "saturation": 0.75,
            "contrast": 1,
            "tintR": 1.15,
            "tintG": 1.05,
            "tintB": 1.20,
            "warmth": 1.05,
            "vignette": 0.00,
            "noise": 0.00,
            "sharpness": 0.70,
            "blur": 0.25,
            "texture_strength": 0.15
        },
        "tags": ["pastel", "feminine", "soft", "fresh"],
    },
    {
        "id": "cool",
        "name": "Cool",
        "description": "Low saturation, cool tones, strong contrast, creating a calm atmosphere",
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
        "tags": ["cool", "cold", "sophisticated", "calm"],
    },
]


def get_all_templates() -> list[StyleTemplate]:
    """Get all style templates"""
    return STYLE_TEMPLATES


def get_template_by_id(template_id: str) -> StyleTemplate | None:
    """Get a single template by ID"""
    for template in STYLE_TEMPLATES:
        if template["id"] == template_id:
            return template
    return None


def search_templates_by_tag(tag: str) -> list[StyleTemplate]:
    """Search templates by tag"""
    return [t for t in STYLE_TEMPLATES if tag in t["tags"]]
