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

  // Clamp to valid range
  color = clamp(color, 0.0, 1.0);

  fragColor = color;
}
