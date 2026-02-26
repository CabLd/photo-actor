import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/style_template.dart';

class CaptureStore {
  static const String _boxName = 'capture_meta';

  static Box<String> _box() => Hive.box<String>(_boxName);

  static Future<void> saveCaptureMeta({
    required String imagePath,
    required int createdAtMs,
    StyleTemplate? template,
    required ShaderParams currentParams,
  }) async {
    final id = 'capture_$createdAtMs';
    final templateJson =
        template == null ? '' : jsonEncode(template.toJson());
    final shaderParamsJson = jsonEncode(currentParams.toJson());

    final payload = <String, dynamic>{
      'id': id,
      'imagePath': imagePath,
      'createdAt': createdAtMs,
      'filterType': template == null ? 'custom' : 'template',
      'templateId': template?.id ?? '',
      'templateJson': templateJson,
      'shaderParamsJson': shaderParamsJson,
    };

    await _box().put(id, jsonEncode(payload));
    await _box().put('latest_capture_id', id);
  }
}

