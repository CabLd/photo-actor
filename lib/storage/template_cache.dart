import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/style_template.dart';
import '../services/template_service.dart';

class TemplateCache {
  static const String _boxName = 'template_cache';
  static const String _keyDidAttemptInitialFetch = 'did_attempt_initial_fetch';
  static const String _keyTemplatesJson = 'templates_json';
  static const String _keyCachedAt = 'templates_cached_at';

  static Box<String> _box() => Hive.box<String>(_boxName);

  static bool get _didAttemptInitialFetch =>
      _box().get(_keyDidAttemptInitialFetch) == '1';

  static Future<void> attemptInitialFetchOnce() async {
    if (_didAttemptInitialFetch) return;

    // User requirement: only attempt once even if it fails.
    await _box().put(_keyDidAttemptInitialFetch, '1');

    try {
      final resp = await TemplateService.getAllTemplates().timeout(
        const Duration(seconds: 8),
      );
      final jsonStr = jsonEncode(resp.toJson());
      await _box().put(_keyTemplatesJson, jsonStr);
      await _box().put(
        _keyCachedAt,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (_) {
      // Do nothing; never retry per requirement.
    }
  }

  static List<StyleTemplate> loadCachedTemplates() {
    final jsonStr = _box().get(_keyTemplatesJson);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final resp = TemplatesResponse.fromJson(map);
      return resp.templates;
    } catch (_) {
      return [];
    }
  }
}

