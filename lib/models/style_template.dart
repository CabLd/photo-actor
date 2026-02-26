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
  final double brightness;
  final double saturation;
  final double contrast;
  final double tintR;
  final double tintG;
  final double tintB;
  final double warmth;
  final double vignette;
  final double noise;
  final double sharpness;
  final double blur;
  @JsonKey(name: 'texture_strength')
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
  final int count;

  const TemplatesResponse({
    required this.templates,
    required this.count,
  });

  factory TemplatesResponse.fromJson(Map<String, dynamic> json) =>
      _$TemplatesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TemplatesResponseToJson(this);
}
