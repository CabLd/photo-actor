// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StyleTemplate _$StyleTemplateFromJson(Map<String, dynamic> json) =>
    StyleTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      thumbnail: json['thumbnail'] as String,
      shader: ShaderParams.fromJson(json['shader'] as Map<String, dynamic>),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$StyleTemplateToJson(StyleTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'thumbnail': instance.thumbnail,
      'shader': instance.shader,
      'tags': instance.tags,
    };

ShaderParams _$ShaderParamsFromJson(Map<String, dynamic> json) => ShaderParams(
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

Map<String, dynamic> _$ShaderParamsToJson(ShaderParams instance) =>
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

TemplatesResponse _$TemplatesResponseFromJson(Map<String, dynamic> json) =>
    TemplatesResponse(
      templates: (json['templates'] as List<dynamic>)
          .map((e) => StyleTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$TemplatesResponseToJson(TemplatesResponse instance) =>
    <String, dynamic>{'templates': instance.templates, 'count': instance.count};
