import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class TechStyleZoomControl extends StatefulWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoomChanged;
  final List<double> zoomOptions;

  const TechStyleZoomControl({
    Key? key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
    this.zoomOptions = const [0.7, 1.0, 2.0, 5.0],
  }) : super(key: key);

  @override
  State<TechStyleZoomControl> createState() => _TechStyleZoomControlState();
}

class _TechStyleZoomControlState extends State<TechStyleZoomControl>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // For the ruler scrolling
  double _dragStartZoom = 1.0;
  double _dragStartPosition = 0.0;

  // Constants for the ruler
  static const double _tickSpacing = 15.0; // Keep in sync with Painter
  static const double _pixelsPerZoomUnit =
      150.0; // How many pixels for 1x zoom change (spacing / scale * 1.0)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleButtonTap(double zoom) {
    if (_isExpanded) return;
    HapticFeedback.selectionClick();
    widget.onZoomChanged(zoom);
  }

  void _startExpansion(double startZoom, double globalX) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = true;
      _dragStartZoom = widget.currentZoom;
      _dragStartPosition = globalX;
    });
    _animationController.forward();
  }

  void _endExpansion() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  void _handleDragUpdate(double globalX) {
    if (!_isExpanded) return;

    final deltaX = _dragStartPosition - globalX; // Drag left to increase zoom
    final zoomDelta = deltaX / _pixelsPerZoomUnit;

    // Using exponential scaling for more natural zoom feeling
    // NewZoom = StartZoom * (1 + delta)
    // Or simple linear for now:
    double newZoom = _dragStartZoom + zoomDelta;

    // Clamp
    newZoom = newZoom.clamp(widget.minZoom, widget.maxZoom);

    if ((newZoom - widget.currentZoom).abs() > 0.01) {
      widget.onZoomChanged(newZoom);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        if (!_isExpanded) {
          // If we drag on the container, maybe we should expand?
          // Ideally we only expand on long press on buttons, but let's allow drag too?
          // For now, let's stick to the button long press as the trigger.
        }
      },
      onHorizontalDragUpdate: (details) {
        if (_isExpanded) {
          // Calculate delta based on drag
          // We need absolute position tracking, so let's use the delta from the update
          final zoomDelta =
              -details.primaryDelta! /
              _pixelsPerZoomUnit *
              2; // *2 for sensitivity
          double newZoom = widget.currentZoom + zoomDelta;
          newZoom = newZoom.clamp(widget.minZoom, widget.maxZoom);
          widget.onZoomChanged(newZoom);
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isExpanded) {
          _endExpansion();
        }
      },
      child: Container(
        height: 100, // Fixed height area
        alignment: Alignment.bottomCenter,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // The Expanded Ruler View
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                final opacity = _expandAnimation.value;
                if (opacity == 0) return const SizedBox.shrink();

                return Opacity(
                  opacity: opacity,
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // The Ruler
                        CustomPaint(
                          size: Size(MediaQuery.of(context).size.width, 60),
                          painter: ZoomRulerPainter(
                            zoom: widget.currentZoom,
                            minZoom: widget.minZoom,
                            maxZoom: widget.maxZoom,
                            primaryColor: Colors.orangeAccent,
                            tickSpacing: _tickSpacing,
                          ),
                        ),
                        // Center Indicator
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 2,
                            height: 20,
                            color: Colors.orange,
                          ),
                        ),
                        // Current Value Text
                        Positioned(
                          bottom: 30,
                          child: Text(
                            "${widget.currentZoom.toStringAsFixed(1)}x",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: "monospace",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // The Collapsed Button View
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                // Fade out buttons when expanded
                final opacity = 1.0 - _expandAnimation.value;
                if (opacity <= 0) return const SizedBox.shrink();

                return Opacity(
                  opacity: opacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.zoomOptions.map((option) {
                      final isSelected =
                          (widget.currentZoom - option).abs() < 0.1;
                      return GestureDetector(
                        onTap: () => _handleButtonTap(option),
                        onLongPressStart: (details) {
                          _startExpansion(option, details.globalPosition.dx);
                        },
                        onLongPressMoveUpdate: (details) {
                          _handleDragUpdate(details.globalPosition.dx);
                        },
                        onLongPressEnd: (details) => _endExpansion(),
                        onLongPressUp: () => _endExpansion(),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.black.withOpacity(0.6)
                                : Colors.black.withOpacity(0.3),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${option}x",
                            style: TextStyle(
                              color: isSelected ? Colors.orange : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ZoomRulerPainter extends CustomPainter {
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final Color primaryColor;
  final double tickSpacing;

  ZoomRulerPainter({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.primaryColor,
    required this.tickSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final Paint activePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double spacing = tickSpacing; // Pixels between ticks
    final double scale = 0.1; // Zoom unit per tick (e.g., every 0.1x is a tick)

    // Calculate visible range
    // We want to draw ticks around the current zoom
    // Ticks are at: 0.1, 0.2, ... 1.0, 1.1 ...

    final int totalTicks = ((maxZoom - minZoom) / scale).ceil();
    // Determine which tick is at the center
    // Center corresponds to 'zoom'

    // Draw loop
    // We iterate through potential ticks and draw if they are on screen
    // The position of a tick value 'v' relative to center is:
    // x = centerX + (v - zoom) / scale * spacing

    // Optimization: find start and end index
    final double screenHalfWidth = size.width / 2;
    final double zoomRangeVisible = (screenHalfWidth / spacing) * scale;

    final double startZoom = (zoom - zoomRangeVisible).clamp(minZoom, maxZoom);
    final double endZoom = (zoom + zoomRangeVisible).clamp(minZoom, maxZoom);

    // Snap to nearest scale step
    final int startIndex = (startZoom / scale).floor();
    final int endIndex = (endZoom / scale).ceil();

    for (int i = startIndex; i <= endIndex; i++) {
      final double value = i * scale;
      if (value < minZoom || value > maxZoom) continue;

      final double x = centerX + (value - zoom) / scale * spacing;

      // Determine tick height
      double height = 10.0;
      bool isMajor = false;

      // Major ticks every 1.0 or 0.5?
      // Let's say every 1.0 is major, every 0.5 is medium
      if ((value - value.round()).abs() < 0.001) {
        height = 20.0;
        isMajor = true;
      } else if (((value * 2) - (value * 2).round()).abs() < 0.001) {
        height = 15.0;
      }

      // Draw tick
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - height),
        isMajor ? activePaint : linePaint,
      );

      // Draw text for major ticks
      if (isMajor) {
        final textSpan = TextSpan(
          text: "${value.round()}x",
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - height - 15),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ZoomRulerPainter oldDelegate) {
    return oldDelegate.zoom != zoom ||
        oldDelegate.minZoom != minZoom ||
        oldDelegate.maxZoom != maxZoom;
  }
}
