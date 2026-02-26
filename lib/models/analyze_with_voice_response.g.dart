// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analyze_with_voice_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyzeWithVoiceResponse _$AnalyzeWithVoiceResponseFromJson(
  Map<String, dynamic> json,
) => AnalyzeWithVoiceResponse(
  analysis: AnalysisBlock.fromJson(json['analysis'] as Map<String, dynamic>),
  shader: ShaderBlock.fromJson(json['shader'] as Map<String, dynamic>),
  voiceGuide: json['voice_guide'] as String,
  readyToCapture: json['ready_to_capture'] as bool,
  voiceGuideAudioBase64: json['voice_guide_audio_base64'] as String? ?? '',
  voiceGuideAudioContentType:
      json['voice_guide_audio_content_type'] as String? ?? 'audio/mpeg',
);

Map<String, dynamic> _$AnalyzeWithVoiceResponseToJson(
  AnalyzeWithVoiceResponse instance,
) => <String, dynamic>{
  'analysis': instance.analysis.toJson(),
  'shader': instance.shader.toJson(),
  'voice_guide': instance.voiceGuide,
  'ready_to_capture': instance.readyToCapture,
  'voice_guide_audio_base64': instance.voiceGuideAudioBase64,
  'voice_guide_audio_content_type': instance.voiceGuideAudioContentType,
};

AnalysisBlock _$AnalysisBlockFromJson(Map<String, dynamic> json) =>
    AnalysisBlock(
      lightDirection: json['light_direction'] as String,
      subjectMood: json['subject_mood'] as String,
      compositionTip: json['composition_tip'] as String,
    );

Map<String, dynamic> _$AnalysisBlockToJson(AnalysisBlock instance) =>
    <String, dynamic>{
      'light_direction': instance.lightDirection,
      'subject_mood': instance.subjectMood,
      'composition_tip': instance.compositionTip,
    };

ShaderBlock _$ShaderBlockFromJson(Map<String, dynamic> json) => ShaderBlock(
  brightness: (json['brightness'] as num).toDouble(),
  saturation: (json['saturation'] as num).toDouble(),
  contrast: (json['contrast'] as num).toDouble(),
  tintR: (json['tintR'] as num).toDouble(),
  tintG: (json['tintG'] as num).toDouble(),
  tintB: (json['tintB'] as num).toDouble(),
  warmth: (json['warmth'] as num).toDouble(),
  vignette: (json['vignette'] as num).toDouble(),
  noise: (json['noise'] as num).toDouble(),
  sharpness: (json['sharpness'] as num).toDouble(),
  blur: (json['blur'] as num).toDouble(),
  textureStrength: (json['texture_strength'] as num).toDouble(),
);

Map<String, dynamic> _$ShaderBlockToJson(ShaderBlock instance) =>
    <String, dynamic>{
      'brightness': instance.brightness,
      'saturation': instance.saturation,
      'contrast': instance.contrast,
      'tintR': instance.tintR,
      'tintG': instance.tintG,
      'tintB': instance.tintB,
      'warmth': instance.warmth,
      'vignette': instance.vignette,
      'noise': instance.noise,
      'sharpness': instance.sharpness,
      'blur': instance.blur,
      'texture_strength': instance.textureStrength,
    };
