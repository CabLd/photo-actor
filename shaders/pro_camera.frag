#version 460 core
#include <flutter/runtime_effect.glsl>

// Auto-set by Flutter ImageFilter engine (do not set from Dart)
uniform vec2 u_size;
uniform sampler2D u_texture;

// Custom uniforms - set from Dart
uniform float uBrightness;   // -1.0 to 1.0
uniform float uSaturation;   // 0.0 to 2.0
uniform float uContrast;     // 0.5 to 1.5
uniform vec3 uTint;          // RGB tint
uniform float uWarmth;       // 0.0 = cool, 1.0 = neutral, 2.0 = warm
uniform float uVignette;     // 0.0 = off, 1.0 = strong

// --- 新增变量 ---
uniform float uNoise;           // 0.0 to 1.0
uniform float uSharpness;       // 1.0 = normal, 2.0 = sharp
uniform float uBlur;            // 0.0 to 1.0
uniform float uTextureStrength; // 0.0 to 1.0

out vec4 fragColor;

// 简单的伪随机函数，用于生成噪点
float rand(vec2 co) {
return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / u_size;
    #ifdef IMPELLER_TARGET_OPENGLES
    // OpenGL ES flips Y - unflip for correct sampling
    uv.y = 1.0 - uv.y;
    #endif

    // 这里的 offset 决定了采样半径
    float offset = (uBlur * 0.005) + (uSharpness > 1.0 ? 0.001 : 0.0);
    vec4 color = texture(u_texture, uv);

    // 如果有模糊或锐化需求，采样周边四个点
    if (uBlur > 0.01 || uSharpness > 1.0) {
        vec4 avgColor = (
            texture(u_texture, uv + vec2(offset, offset)) +
            texture(u_texture, uv + vec2(-offset, offset)) +
            texture(u_texture, uv + vec2(offset, -offset)) +
            texture(u_texture, uv + vec2(-offset, -offset))
        ) * 0.25;
        
        // 模糊：向平均色靠拢
        color = mix(color, avgColor, uBlur);
        
        // 锐化：减去模糊部分（高通滤波原理）
        if (uSharpness > 1.0) {
            color.rgb += (color.rgb - avgColor.rgb) * (uSharpness - 1.0) * 2.0;
        }
    }

    // Apply brightness: add offset to RGB
    color.rgb += uBrightness;

    // Apply contrast: scale around midpoint 0.5
    color.rgb = (color.rgb - 0.5) * uContrast + 0.5;

    // Apply saturation: blend with luminance
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(luminance), color.rgb, uSaturation);

    // Apply tint: multiply RGB by tint
    color.rgb *= uTint;

    // Apply warmth: shift toward red/orange (0=cool, 1=neutral, 2=warm)
    float w = (uWarmth - 1.0) * 0.5;
    color.r += w;
    color.b -= w;

    if (uNoise > 0.0 || uTextureStrength > 0.0) {
        float noiseVal = rand(uv);
        // Noise 增加随机明暗，TextureStrength 模拟粗糙感
        float combinedNoise = (noiseVal - 0.5) * (uNoise + uTextureStrength * 0.5);
        color.rgb += combinedNoise;
    };

    // Apply vignette: darken toward edges
    vec2 cen = uv - 0.5;
    float dist = length(cen) * 1.414;
    color.rgb *= 1.0 - uVignette * smoothstep(0.4, 1.0, dist);

    // Clamp to valid range
    color = clamp(color, 0.0, 1.0);

    fragColor = color;
}
