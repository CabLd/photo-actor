import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/style_template.dart';

class TemplateService {
  static const String baseUrl = 'http://10.249.213.118:8000';

  /// 获取所有模板
  static Future<TemplatesResponse> getAllTemplates() async {
    final response = await http.get(Uri.parse('$baseUrl/api/templates'));

    if (response.statusCode == 200) {
      return TemplatesResponse.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Failed to load templates: ${response.statusCode}');
    }
  }

  /// 根据标签搜索模板
  static Future<TemplatesResponse> searchTemplatesByTag(String tag) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/templates?tag=$tag'),
    );

    if (response.statusCode == 200) {
      return TemplatesResponse.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Failed to search templates: ${response.statusCode}');
    }
  }

  /// 根据 ID 获取单个模板
  static Future<StyleTemplate> getTemplateById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/templates/$id'));

    if (response.statusCode == 200) {
      return StyleTemplate.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Failed to load template: ${response.statusCode}');
    }
  }
}
