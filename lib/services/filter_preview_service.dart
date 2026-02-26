import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../models/style_template.dart';

/// Service for generating filter preview images
class FilterPreviewService {
  static ui.FragmentProgram? _fragmentProgram;
  static bool _isInitialized = false;

  /// Initialize the shader program
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _fragmentProgram = await ui.FragmentProgram.fromAsset(
        'shaders/pro_camera.frag',
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to load shader: $e');
    }
  }

  /// Generate a preview image by applying the template's shader to the source image
  static Future<ui.Image> generatePreview({
    required ui.Image sourceImage,
    required StyleTemplate template,
  }) async {
    if (!_isInitialized || _fragmentProgram == null) {
      await initialize();
    }

    final shader = _fragmentProgram!.fragmentShader();
    final params = template.shader;

    // Set shader parameters (indices match pro_camera.frag uniforms)
    shader.setFloat(2, params.brightness);
    shader.setFloat(3, params.saturation);
    shader.setFloat(4, params.contrast);
    shader.setFloat(5, params.tintR);
    shader.setFloat(6, params.tintG);
    shader.setFloat(7, params.tintB);
    shader.setFloat(8, params.warmth);
    shader.setFloat(9, params.vignette);
    shader.setFloat(10, params.noise);
    shader.setFloat(11, params.sharpness);
    shader.setFloat(12, params.blur);
    shader.setFloat(13, params.textureStrength);

    final w = sourceImage.width;
    final h = sourceImage.height;
    final rect = ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, rect);
    final paint = ui.Paint()..imageFilter = ui.ImageFilter.shader(shader);

    canvas.saveLayer(rect, paint);
    canvas.drawImage(sourceImage, ui.Offset.zero, ui.Paint());
    canvas.restore();

    final picture = recorder.endRecording();
    final filteredImage = await picture.toImage(w, h);

    return filteredImage;
  }

  /// Load image from asset bundle
  static Future<ui.Image> loadImageFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Load image from file
  static Future<ui.Image> loadImageFromFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Convert ui.Image to PNG bytes
  static Future<Uint8List> imageToPngBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to encode image to PNG');
    }
    return byteData.buffer.asUint8List();
  }
}
