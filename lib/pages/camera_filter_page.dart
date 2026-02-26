import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:audio_helper/audio_helper.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../commons/filePathHelper.dart';
import '../commons/sizeConfig.dart';
import '../commons/string.dart';
import '../manager/PermissionHelper.dart';
import '../models/analyze_with_voice_response.dart';
import '../models/style_template.dart';
import '../widgets/actionButton.dart';
import '../widgets/breathingRecordDot.dart';
import 'filter_library_page.dart';

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
  bool _useFrontCamera = false;
  AudioHelper _audioHelper = AudioHelper(minRecordSeconds: 1);
  static const int _minRecordSeconds = 1;
  bool _isRecording = false;
  bool _isAskingAi = false;

  static String get _apiBaseUrl {
    return 'http://10.249.213.118:8000';
  }

  // Shader parameters
  double _brightness = 0.0; // -1.0 to 1.0
  double _saturation = 1.0; // 0.0 to 2.0
  double _contrast = 1.0; // 0.5 to 1.5
  double _tintR = 1.0; // 0.0 to 2.0
  double _tintG = 1.0;
  double _tintB = 1.0;
  double _warmth = 1.0; // 0.0 = cool, 1.0 = neutral, 2.0 = warm
  double _vignette = 0.0; // 0.0 = off, 1.0 = strong
  double _noise = 0.0; // 0.0 = off, 1.0 = strong
  double _sharpness = 1.0; // 0.0 = off, 1.0 = strong
  double _blur = 0.0; // 0.0 = off, 1.0 = strong
  double _textureStrength = 0.0; // 0.0 = off, 1.0 = strong

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
    _audioHelper = AudioHelper(minRecordSeconds: _minRecordSeconds);
    _loadShader();
    _initCamera();
    _startFpsCounter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioHelper.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (_controller == null || !_controller!.value.isInitialized) return;
    // if (state == AppLifecycleState.inactive) {
    //   _controller?.dispose();
    // } else if (state == AppLifecycleState.resumed) {
    //   _initCamera();
    // }
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/pro_camera.frag',
      );
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
      final target = _cameras!.firstWhere(
        (c) =>
            c.lensDirection ==
            (_useFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => _cameras!.first,
      );
      final newController = CameraController(
        target,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await newController.initialize();
      if (!mounted) return;
      final old = _controller;
      _controller = newController;
      setState(() {
        _isInitialized = true;
        _error = null;
      });
      old?.dispose();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Camera init failed: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    final nextFront = !_useFrontCamera;
    setState(() {
      _isInitialized = false;
      _useFrontCamera = nextFront;
    });
    _controller?.dispose();
    _controller = null;
    await _initCamera();
  }

  /// 开始录音：使用 getChatAudioFilePathAsync 获取路径并启动录制（避免 appDocDir 未初始化导致路径为 /chat 报错）
  Future<void> _startVoiceRecord() async {
    if (!PermissionHelper.micPermission.isGranted) {
      await PermissionHelper.requestMicrophonePermission(
        Strings.requestMicrophonePermissionDenied,
      );
      PermissionHelper.getMicPermission();
      return;
    }
    final path = FilePathHelper.getChatAudioFilePath(
      '${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法创建录音文件路径，请重试')));
      return;
    }
    try {
      HapticFeedback.lightImpact().then((value) {
        HapticFeedback.lightImpact();
      });
      await _audioHelper.startRecord(path: path, config: RecordConfig());
      if (mounted) {
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('开始录音失败: $e')));
      }
    }
  }

  /// 手势停止录音；过短时提示；通过则截帧并请求 /api/analyze_with_voice
  Future<void> _stopVoiceRecord() async {
    if (!_isRecording) return;
    try {
      final result = await _audioHelper.stopRecord();
      if (!mounted) return;
      setState(() => _isRecording = false);
      if (result == null) return;
      if (result.duration.inSeconds < _minRecordSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音过短，请至少录制 $_minRecordSeconds 秒')),
        );
        return;
      }
      await _captureFrameAndAskAi(result.path);
    } catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('停止录音失败: $e')));
      }
    }
  }

  /// 截取当前相机一帧（JPEG），与录音一并请求 /api/analyze_with_voice，并应用返回参数
  Future<void> _captureFrameAndAskAi(String audioPath) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isAskingAi = true);
    try {
      final imageBase64 = await _captureCurrentFrameBase64();
      if (imageBase64 == null || imageBase64.isEmpty) {
        if (mounted) {
          setState(() => _isAskingAi = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('截取画面失败')));
        }
        return;
      }
      final audioBytes = await File(audioPath).readAsBytes();
      final audioBase64 = base64Encode(audioBytes);

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/analyze_with_voice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio_base64': audioBase64,
          'image_base64': imageBase64,
          'audio_media_type': 'audio/mp4',
        }),
      );

      if (!mounted) return;
      setState(() => _isAskingAi = false);

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请求失败: ${response.statusCode} ${response.body}'),
          ),
        );
        return;
      }

      final resp = AnalyzeWithVoiceResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      _applyDirectorResponse(resp);

      if (resp.voiceGuideAudioBase64.isNotEmpty) {
        _playVoiceGuideAudio(resp.voiceGuideAudioBase64);
      } else if (resp.voiceGuide.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resp.voiceGuide)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAskingAi = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('请求失败: $e')));
      }
    }
  }

  /// 截取当前预览一帧，返回 JPEG 的 Base64，失败返回 null
  Future<String?> _captureCurrentFrameBase64() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    try {
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// 将 /api/analyze_with_voice 返回的 shader 等写入当前状态
  void _applyDirectorResponse(AnalyzeWithVoiceResponse resp) {
    final shader = resp.shader;
    setState(() {
      _brightness = shader.brightness;
      _saturation = shader.saturation;
      // _contrast = shader.contrast;
      _tintR = shader.tintR;
      _tintG = shader.tintG;
      _tintB = shader.tintB;
      _warmth = shader.warmth;
      _vignette = shader.vignette;
      _noise = shader.noise;
      _sharpness = shader.sharpness;
      _blur = shader.blur;
      _textureStrength = shader.textureStrength;
    });
  }

  /// 播放 voice_guide 的 TTS 音频（Base64）
  void _playVoiceGuideAudio(String base64Audio) {
    try {
      final bytes = base64Decode(base64Audio);
      final tempDir = Directory.systemTemp;
      final file = File(
        '${tempDir.path}/voice_guide_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      file.writeAsBytesSync(bytes);
      _audioHelper.play(url: file.path, isLocal: true);
    } catch (_) {}
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
      body: SafeArea(child: _buildBody()),
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
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

        // Control panel
        // Positioned(left: 0, right: 0, bottom: 150, child: _buildControlPanel()),

        // FPS
        // Positioned(top: 8, right: 8, child: _buildFpsBadge()),

        // 滤镜库按钮（左上角）
        Positioned(top: 48, left: 16, child: _buildFilterLibraryButton()),

        // 请求 AI 时的 loading
        if (_isAskingAi)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('AI 分析中…', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    final size = _controller!.value.previewSize;
    if (size == null) return const SizedBox.expand();

    // 传感器多为横屏 (width > height)，竖屏显示需交换宽高，否则画面被拉长
    final needSwap = size.width > size.height;
    final previewW = needSwap ? size.height : size.width;
    final previewH = needSwap ? size.width : size.height;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  width: previewW,
                  height: previewH,
                  child: CameraPreview(
                    _controller!,
                    key: ValueKey(_useFrontCamera),
                  ),
                ),
                if (_shaderReady && _fragmentProgram != null)
                  Positioned.fill(child: _buildShaderOverlay()),
              ],
            ),
            SizedBox(
              width: SizeConfig.screenWidth,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _isRecording
                        ? BreathingRecordDot()
                        : const SizedBox.shrink(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSwitchCameraButton(),
                        _actionButton(),
                        _voiceButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton() {
    return ActionButton(onTap: () {});
  }

  Widget _voiceButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startVoiceRecord(),
      onLongPressEnd: (_) => _stopVoiceRecord(),
      onLongPressCancel: () => _stopVoiceRecord(),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_none, size: 50, color: Colors.white),
            // const SizedBox(height: 8),
            // Text(
            //   _isRecording ? '松开发送' : '长按录音',
            //   style: TextStyle(
            //     color: _isRecording ? Colors.red : Colors.white70,
            //     fontSize: 14,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCameraButton() {
    final hasMultiple = _cameras != null && _cameras!.length >= 2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasMultiple ? _switchCamera : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.cameraswitch,
            color: hasMultiple ? Colors.white : Colors.white38,
            size: 43,
          ),
        ),
      ),
    );
  }

  /// 滤镜库按钮
  Widget _buildFilterLibraryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openFilterLibrary,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_filter, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              const Text(
                '滤镜库',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开滤镜库并应用选中的滤镜
  Future<void> _openFilterLibrary() async {
    final selectedTemplate = await Navigator.push<StyleTemplate>(
      context,
      MaterialPageRoute(builder: (context) => const FilterLibraryPage()),
    );

    if (selectedTemplate != null) {
      _applyTemplate(selectedTemplate);
    }
  }

  /// 应用滤镜模板
  void _applyTemplate(StyleTemplate template) {
    setState(() {
      final shader = template.shader;
      _brightness = shader.brightness;
      _saturation = shader.saturation;
      _contrast = shader.contrast;
      _tintR = shader.tintR;
      _tintG = shader.tintG;
      _tintB = shader.tintB;
      _warmth = shader.warmth;
      _vignette = shader.vignette;
      _noise = shader.noise;
      _sharpness = shader.sharpness;
      _blur = shader.blur;
      _textureStrength = shader.textureStrength;
    });

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已应用「${template.name}」滤镜'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildShaderOverlay() {
    final shader = _fragmentProgram!.fragmentShader();

    // Uniform indices: 0,1=u_size (engine), 2=uBrightness, 3=uSaturation, 4=uContrast, 5,6,7=uTint, 8=uWarmth, 9=uVignette
    shader.setFloat(2, _brightness);
    shader.setFloat(3, _saturation);
    shader.setFloat(4, _contrast);
    shader.setFloat(5, _tintR);
    shader.setFloat(6, _tintG);
    shader.setFloat(7, _tintB);
    shader.setFloat(8, _warmth);
    shader.setFloat(9, _vignette);
    shader.setFloat(10, _noise);
    shader.setFloat(11, _sharpness);
    shader.setFloat(12, _blur);
    shader.setFloat(13, _textureStrength);

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
          _buildSlider(
            'Brightness',
            _brightness,
            -1.0,
            1.0,
            (v) => setState(() => _brightness = v),
          ),
          _buildSlider(
            'Saturation',
            _saturation,
            0.0,
            2.0,
            (v) => setState(() => _saturation = v),
          ),
          _buildSlider(
            'Contrast',
            _contrast,
            -1.0,
            1.0,
            (v) => setState(() => _contrast = v),
          ),
          _buildSlider(
            'Tint R',
            _tintR,
            0.0,
            2.0,
            (v) => setState(() => _tintR = v),
          ),
          _buildSlider(
            'Tint G',
            _tintG,
            0.0,
            2.0,
            (v) => setState(() => _tintG = v),
          ),
          _buildSlider(
            'Tint B',
            _tintB,
            0.0,
            2.0,
            (v) => setState(() => _tintB = v),
          ),
          _buildSlider(
            'Warmth',
            _warmth,
            0.0,
            2.0,
            (v) => setState(() => _warmth = v),
          ),
          _buildSlider(
            'Vignette',
            _vignette,
            0.0,
            1.0,
            (v) => setState(() => _vignette = v),
          ),
          _buildSlider(
            'Noise',
            _noise,
            0.0,
            1.0,
            (v) => setState(() => _noise = v),
          ),
          _buildSlider(
            'Sharpness',
            _sharpness,
            0.0,
            2.0,
            (v) => setState(() => _sharpness = v),
          ),
          _buildSlider(
            'Blur',
            _blur,
            0.0,
            1.0,
            (v) => setState(() => _blur = v),
          ),
          _buildSlider(
            'Texture Strength',
            _textureStrength,
            0.0,
            1.0,
            (v) => setState(() => _textureStrength = v),
          ),
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
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
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
