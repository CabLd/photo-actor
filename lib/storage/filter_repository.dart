import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/style_template.dart';
import '../services/template_service.dart';

class FilterRepository {
  static const String boxName = 'filters';

  static const String _keyDidAttemptInitialFetch =
      'meta:did_attempt_initial_fetch';

  static const String _keyPrefixTemplate = 'tpl:';
  static const String _keyPrefixSource = 'meta:source:';
  static const String _keyPrefixUpdatedAt = 'meta:updated_at:';

  static Box<String> _box() => Hive.box<String>(boxName);

  static Future<void> attemptInitialRemoteFetchOnce() async {
    final box = _box();
    if (box.get(_keyDidAttemptInitialFetch) == '1') return;

    // Requirement: only attempt once, even if it fails.
    await box.put(_keyDidAttemptInitialFetch, '1');

    try {
      final resp = await TemplateService.getAllTemplates().timeout(
        const Duration(seconds: 8),
      );
      for (final t in resp.templates) {
        await upsertRemoteTemplate(t);
      }
    } catch (_) {
      // Swallow: never retry per requirement.
    }
  }

  static Future<void> upsertRemoteTemplate(StyleTemplate template) async {
    final box = _box();
    final templateKey = '$_keyPrefixTemplate${template.id}';
    await box.put(templateKey, jsonEncode(template.toJson()));
    await box.put('$_keyPrefixSource${template.id}', 'remote');
    // Remote templates have no local "updatedAt"; keep 0 for stable ordering.
    await box.put('$_keyPrefixUpdatedAt${template.id}', '0');
  }

  static Future<void> touchTemplate(String templateId) async {
    final box = _box();
    await box.put(
      '$_keyPrefixUpdatedAt$templateId',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  static List<StyleTemplate> loadAllTemplates() {
    final box = _box();
    final result = <_TemplateWithMeta>[];

    for (final key in box.keys) {
      if (key is! String) continue;
      if (!key.startsWith(_keyPrefixTemplate)) continue;
      final raw = box.get(key);
      if (raw == null || raw.isEmpty) continue;

      final templateId = key.substring(_keyPrefixTemplate.length);
      final source = box.get('$_keyPrefixSource$templateId') ?? '';
      final updatedAt =
          int.tryParse(box.get('$_keyPrefixUpdatedAt$templateId') ?? '') ?? 0;

      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final t = StyleTemplate.fromJson(map);
        result.add(
          _TemplateWithMeta(
            template: t,
            source: source,
            updatedAtMs: updatedAt,
          ),
        );
      } catch (_) {
        // Ignore corrupted entry
      }
    }

    result.sort((a, b) {
      final aLocal = _isLocal(a);
      final bLocal = _isLocal(b);
      if (aLocal != bLocal) return aLocal ? -1 : 1;

      // Local templates: most recent first; Remote templates keep stable order by name.
      if (aLocal && bLocal) {
        final cmp = b.updatedAtMs.compareTo(a.updatedAtMs);
        if (cmp != 0) return cmp;
      }
      return a.template.name.compareTo(b.template.name);
    });

    return result.map((e) => e.template).toList(growable: false);
  }

  static bool _isLocal(_TemplateWithMeta item) {
    if (item.source == 'local') return true;
    return item.template.id.startsWith('local_');
  }

  static String _fnv1a64Hex(String input) {
    const int fnvOffsetBasis = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    var hash = fnvOffsetBasis;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  static Future<StyleTemplate> upsertLocalTemplateFromParams(
    ShaderParams params, {
    String? thumbnailPath,
  }) async {
    final box = _box();
    final paramsJson = jsonEncode(params.toJson());
    final hash = _fnv1a64Hex(paramsJson);
    final id = 'local_$hash';

    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = DateTime.fromMillisecondsSinceEpoch(now);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    final template = StyleTemplate(
      id: id,
      name: 'Custom Filter',
      description: 'Local saved $y-$m-$d $hh:$mm',
      thumbnail: thumbnailPath ?? '',
      shader: params,
      tags: const ['local'],
    );

    await box.put('$_keyPrefixTemplate$id', jsonEncode(template.toJson()));
    await box.put('$_keyPrefixSource$id', 'local');
    await box.put('$_keyPrefixUpdatedAt$id', now.toString());

    return template;
  }
}

class _TemplateWithMeta {
  const _TemplateWithMeta({
    required this.template,
    required this.source,
    required this.updatedAtMs,
  });

  final StyleTemplate template;
  final String source;
  final int updatedAtMs;
}
