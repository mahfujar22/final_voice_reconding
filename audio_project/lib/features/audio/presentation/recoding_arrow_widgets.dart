import 'package:flutter/material.dart';

class RecordingArrow extends StatefulWidget {
  const RecordingArrow({super.key});

  @override
  State<RecordingArrow> createState() => _RecordingArrowState();
}

class _RecordingArrowState extends State<RecordingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: Opacity(
            opacity: 0.7 + (_animation.value / 24.0) * 0.3,
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.keyboard_arrow_up_rounded,
        size: 28,
        color: Colors.green,
      ),
    );
  }
}