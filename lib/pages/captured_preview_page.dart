import 'dart:io';

import 'package:flutter/material.dart';

class CapturedPreviewPage extends StatefulWidget {
  const CapturedPreviewPage({
    super.key,
    required this.filePaths,
    required this.initialIndex,
  });

  final List<String> filePaths;
  final int initialIndex;

  @override
  State<CapturedPreviewPage> createState() => _CapturedPreviewPageState();
}

class _CapturedPreviewPageState extends State<CapturedPreviewPage> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.filePaths.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.filePaths.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: total,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final path = widget.filePaths[i];
                  return Center(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      '${_index + 1}/$total',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
