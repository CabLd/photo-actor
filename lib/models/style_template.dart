import 'package:json_annotation/json_annotation.dart';

part 'style_template.g.dart';

/// 风格模板
@JsonSerializable()
class StyleTemplate {
  final String id;
  final String name;
  final String description;
  final String thumbnail;
  final ShaderParams shader;
  final List<String> tags;

  const StyleTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnail,
    required this.shader,
    required this.tags,
  });

  factory StyleTemplate.fromJson(Map<String, dynamic> json) =>
      _$StyleTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$StyleTemplateToJson(this);
}

/// Shader 参数
@JsonSerializable()
class ShaderParams {
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

  const ShaderParams({
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

  factory ShaderParams.fromJson(Map<String, dynamic> json) =>
      _$ShaderParamsFromJson(json);

  Map<String, dynamic> toJson() => _$ShaderParamsToJson(this);
}

/// 模板列表响应
@JsonSerializable()
class TemplatesResponse {
  final List<StyleTemplate> templates;
  @JsonKey(defaultValue: 0)
  final int count;

  const TemplatesResponse({
    required this.templates,
    required this.count,
  });

  factory TemplatesResponse.fromJson(Map<String, dynamic> json) =>
      _$TemplatesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TemplatesResponseToJson(this);
}
