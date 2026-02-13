import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Real-time camera filter research page.
/// Uses Shader (pro_camera.frag) with ImageFilter + BackdropFilter.
/// Requires Impeller backend (default on Android since Flutter 3.16).
class CameraFilterPage extends StatefulWidget {
  const CameraFilterPage({super.key});

  @override
  State<CameraFilterPage> createState() => _CameraFilterPageState();
}

class _CameraFilterPageState extends State<CameraFilterPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String? _error;
  bool _isInitialized = false;

  // Shader parameters
  double _brightness = 0.0; // -1.0 to 1.0
  double _saturation = 1.0; // 0.0 to 2.0
  double _contrast = 1.0; // 0.5 to 1.5
  double _tintR = 1.0; // 0.0 to 2.0
  double _tintG = 1.0;
  double _tintB = 1.0;

  // FPS
  int _frameCount = 0;
  int _fps = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  ui.FragmentProgram? _fragmentProgram;
  bool _shaderReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadShader();
    _initCamera();
    _startFpsCounter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/pro_camera.frag');
      if (mounted) {
        setState(() {
          _fragmentProgram = program;
          _shaderReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Shader load failed: $e';
        });
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras ??= await availableCameras();
      final back = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Camera init failed: $e';
        });
      }
    }
  }

  void _startFpsCounter() {
    void onFrame(_) {
      if (!mounted) return;
      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;
      if (elapsed >= 1000) {
        setState(() {
          _fps = (_frameCount * 1000 / elapsed).round();
          _frameCount = 0;
          _lastFpsUpdate = now;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback(onFrame);
    }
    WidgetsBinding.instance.addPostFrameCallback(onFrame);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() => _error = null);
                  _initCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview as backdrop
        _buildCameraPreview(),

        // Shader filter overlay (BackdropFilter applies shader to content behind)
        if (_shaderReady && _fragmentProgram != null) _buildShaderOverlay(),

        // Control panel
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildControlPanel(),
        ),

        // FPS
        Positioned(
          top: 8,
          right: 8,
          child: _buildFpsBadge(),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _controller!.value.previewSize;
        if (size == null) return const SizedBox.expand();

        final aspectRatio = size.height / size.width;
        return Center(
          child: AspectRatio(
            aspectRatio: 1 / aspectRatio,
            child: CameraPreview(_controller!),
          ),
        );
      },
    );
  }

  Widget _buildShaderOverlay() {
    final shader = _fragmentProgram!.fragmentShader();

    // Uniform indices: 0,1=u_size (engine), 2=uBrightness, 3=uSaturation, 4=uContrast, 5,6,7=uTint
    shader.setFloat(2, _brightness);
    shader.setFloat(3, _saturation);
    shader.setFloat(4, _contrast);
    shader.setFloat(5, _tintR);
    shader.setFloat(6, _tintG);
    shader.setFloat(7, _tintB);

    return ClipRect(
      child: SizedBox.expand(
        child: BackdropFilter(
          filter: ui.ImageFilter.shader(shader),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSlider('Brightness', _brightness, -1.0, 1.0, (v) => setState(() => _brightness = v)),
          _buildSlider('Saturation', _saturation, 0.0, 2.0, (v) => setState(() => _saturation = v)),
          _buildSlider('Contrast', _contrast, 0.5, 1.5, (v) => setState(() => _contrast = v)),
          _buildSlider('Tint R', _tintR, 0.0, 2.0, (v) => setState(() => _tintR = v)),
          _buildSlider('Tint G', _tintG, 0.0, 2.0, (v) => setState(() => _tintG = v)),
          _buildSlider('Tint B', _tintB, 0.0, 2.0, (v) => setState(() => _tintB = v)),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white38,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFpsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$_fps FPS',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
