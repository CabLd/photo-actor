import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/style_template.dart';
import '../storage/filter_repository.dart';
import '../services/filter_preview_service.dart';

/// Filter library page
class FilterLibraryPage extends StatefulWidget {
  const FilterLibraryPage({super.key});

  @override
  State<FilterLibraryPage> createState() => _FilterLibraryPageState();
}

class _FilterLibraryPageState extends State<FilterLibraryPage> {
  List<StyleTemplate> _templates = [];
  List<StyleTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  ui.Image? _demoSourceImage;
  final Map<String, ui.Image> _previewCache = {};

  @override
  void initState() {
    super.initState();
    _loadDemoImage();
    _loadTemplates();
  }

  @override
  void dispose() {
    _demoSourceImage?.dispose();
    for (final image in _previewCache.values) {
      image.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDemoImage() async {
    try {
      final image = await FilterPreviewService.loadImageFromAsset(
        'lib/assets/image.png',
      );
      if (mounted) {
        setState(() {
          _demoSourceImage = image;
        });
      }
    } catch (e) {
      debugPrint('Failed to load demo image: $e');
    }
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FilterPreviewService.initialize();
      setState(() {
        _templates = FilterRepository.loadAllTemplates();
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<ui.Image?> _getPreviewImage(StyleTemplate template) async {
    if (_demoSourceImage == null) return null;

    // Check cache first
    if (_previewCache.containsKey(template.id)) {
      return _previewCache[template.id];
    }

    try {
      final preview = await FilterPreviewService.generatePreview(
        sourceImage: _demoSourceImage!,
        template: template,
      );
      _previewCache[template.id] = preview;
      return preview;
    } catch (e) {
      debugPrint('Failed to generate preview for ${template.id}: $e');
      return null;
    }
  }

  void _applyFilter() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredTemplates = _templates;
      return;
    }

    bool matches(StyleTemplate t) {
      if (t.name.toLowerCase().contains(q)) return true;
      if (t.description.toLowerCase().contains(q)) return true;
      for (final tag in t.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }

    _filteredTemplates = _templates.where(matches).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Filter Library',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search filters...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilter();
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Template list
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTemplates,
              child: const Text('Refresh local cache'),
            ),
          ],
        ),
      );
    }

    if (_filteredTemplates.isEmpty) {
      if (_templates.isEmpty && _searchQuery.trim().isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_filter_outlined,
                color: Colors.white.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No local filters',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              color: Colors.white.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching filters found',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(StyleTemplate template) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, template);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: FutureBuilder<ui.Image?>(
                  future: _getPreviewImage(template),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white.withValues(alpha: 0.5),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      return RawImage(
                        image: snapshot.data,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    }

                    return Container(
                      color: Colors.white.withValues(alpha: 0.05),
                      child: Center(
                        child: Icon(
                          Icons.photo_filter,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Template info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 8),
                  // Wrap(
                  //   spacing: 4,
                  //   runSpacing: 4,
                  //   children: template.tags.take(3).map((tag) {
                  //     return Container(
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 6,
                  //         vertical: 2,
                  //       ),
                  //       decoration: BoxDecoration(
                  //         color: Colors.blue.withValues(alpha: 0.3),
                  //         borderRadius: BorderRadius.circular(4),
                  //       ),
                  //       child: Text(
                  //         tag,
                  //         style: const TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 10,
                  //         ),
                  //       ),
                  //     );
                  //   }).toList(),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
