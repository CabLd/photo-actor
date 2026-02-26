import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BreathingRecordDot extends StatefulWidget {
  const BreathingRecordDot({super.key});

  @override
  State<BreathingRecordDot> createState() => _BreathingRecordDotState();
}

class _BreathingRecordDotState extends State<BreathingRecordDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFED1D1D),
        ),
      ),
    );
  }
}
