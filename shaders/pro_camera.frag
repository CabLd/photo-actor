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

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  // OpenGL ES flips Y - unflip for correct sampling
  uv.y = 1.0 - uv.y;
#endif

  vec4 color = texture(u_texture, uv);

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

  // Apply vignette: darken toward edges
  vec2 cen = uv - 0.5;
  float dist = length(cen) * 1.414;
  color.rgb *= 1.0 - uVignette * smoothstep(0.4, 1.0, dist);

  // Clamp to valid range
  color = clamp(color, 0.0, 1.0);

  fragColor = color;
}
