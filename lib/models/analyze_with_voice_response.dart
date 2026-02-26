import 'package:json_annotation/json_annotation.dart';

part 'analyze_with_voice_response.g.dart';

/// 对应后端 /api/analyze_with_voice 的响应体。
@JsonSerializable(explicitToJson: true)
class AnalyzeWithVoiceResponse {
  AnalyzeWithVoiceResponse({
    required this.analysis,
    required this.shader,
    required this.voiceGuide,
    required this.readyToCapture,
    this.voiceGuideAudioBase64 = '',
    this.voiceGuideAudioContentType = 'audio/mpeg',
  });

  factory AnalyzeWithVoiceResponse.fromJson(Map<String, dynamic> json) =>
      _$AnalyzeWithVoiceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyzeWithVoiceResponseToJson(this);

  final AnalysisBlock analysis;
  final ShaderBlock shader;
  @JsonKey(name: 'voice_guide')
  final String voiceGuide;
  @JsonKey(name: 'ready_to_capture')
  final bool readyToCapture;
  @JsonKey(name: 'voice_guide_audio_base64')
  final String voiceGuideAudioBase64;
  @JsonKey(name: 'voice_guide_audio_content_type')
  final String voiceGuideAudioContentType;
}

@JsonSerializable()
class AnalysisBlock {
  AnalysisBlock({
    required this.lightDirection,
    required this.subjectMood,
    required this.compositionTip,
  });

  factory AnalysisBlock.fromJson(Map<String, dynamic> json) =>
      _$AnalysisBlockFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisBlockToJson(this);

  @JsonKey(name: 'light_direction')
  final String lightDirection;
  @JsonKey(name: 'subject_mood')
  final String subjectMood;
  @JsonKey(name: 'composition_tip')
  final String compositionTip;
}

@JsonSerializable()
class ShaderBlock {
  ShaderBlock({
    required this.brightness,
    required this.saturation,
    required this.contrast,
    required this.tintR,
    required this.tintG,
    required this.tintB,
    required this.warmth,
    required this.vignette,
    required this.noise,
    required this.sharpness,
    required this.blur,
    required this.textureStrength,
  });

  factory ShaderBlock.fromJson(Map<String, dynamic> json) =>
      _$ShaderBlockFromJson(json);

  Map<String, dynamic> toJson() => _$ShaderBlockToJson(this);

  @JsonKey(defaultValue: 1.0)
  final double brightness;
  @JsonKey(defaultValue: 1.0)
  final double saturation;
  @JsonKey(defaultValue: 1.0)
  final double contrast;
  @JsonKey(defaultValue: 1.0)
  final double tintR;
  @JsonKey(defaultValue: 1.0)
  final double tintG;
  @JsonKey(defaultValue: 1.0)
  final double tintB;
  @JsonKey(defaultValue: 1.0)
  final double warmth;
  @JsonKey(defaultValue: 0.0)
  final double vignette;
  @JsonKey(defaultValue: 0.0)
  final double noise;
  @JsonKey(defaultValue: 0.0)
  final double sharpness;
  @JsonKey(defaultValue: 0.0)
  final double blur;
  @JsonKey(name: 'texture_strength', defaultValue: 0.0)
  final double textureStrength;
}
