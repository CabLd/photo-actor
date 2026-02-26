import 'dart:io';

import 'package:flutter/material.dart';

import '../commons/filePathHelper.dart';
import 'captured_preview_page.dart';

class CapturedGalleryPage extends StatefulWidget {
  const CapturedGalleryPage({super.key});

  @override
  State<CapturedGalleryPage> createState() => _CapturedGalleryPageState();
}

class _CapturedGalleryPageState extends State<CapturedGalleryPage> {
  List<File> _files = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final files = FilePathHelper.listCapturedImagesSorted();
      if (!mounted) return;
      setState(() {
        _files = files;
        _selectedIndex = 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _files = [];
        _selectedIndex = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('相册', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildContent() {
    if (_files.isEmpty) {
      return Center(
        child: Text(
          '暂无已保存照片',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          final isSelected = index == _selectedIndex;
          return GestureDetector(
            onTap: () async {
              setState(() => _selectedIndex = index);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CapturedPreviewPage(
                    filePaths: _files
                        .map((e) => e.path)
                        .toList(growable: false),
                    initialIndex: index,
                  ),
                ),
              );
              await _load();
            },
            child: Container(
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                cacheWidth: 300,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: Colors.white.withValues(alpha: 0.06),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
