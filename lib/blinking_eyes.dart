// lib/blinking_eyes.dart

import 'dart:math';
import 'package:flutter/material.dart';

class BlinkingEyes extends StatefulWidget {
  final Color eyeColor;
  final double size;

  const BlinkingEyes({
    Key? key,
    this.eyeColor = Colors.orange,
    this.size = 100.0,
  }) : super(key: key);

  @override
  State<BlinkingEyes> createState() => _BlinkingEyesState();
}

class _BlinkingEyesState extends State<BlinkingEyes>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blink;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _blink = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _repeatBlink();
  }

  Future<void> _repeatBlink() async {
    while (mounted) {
      int waitMs = 1500 + _random.nextInt(3000);
      await Future.delayed(Duration(milliseconds: waitMs));
      if (!mounted) return;
      await _controller.forward();
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double eyeSize = widget.size * (2 / 5);
    final double spacing = widget.size * (1 / 5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Eye(openness: _blink.value, color: widget.eyeColor, size: eyeSize),
            SizedBox(width: spacing),
            Eye(openness: _blink.value, color: widget.eyeColor, size: eyeSize),
          ],
        );
      },
    );
  }
}

class Eye extends StatelessWidget {
  final double openness;
  final double size;
  final Color color;
  const Eye({
    Key? key,
    required this.openness,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: size,
        height: size * openness.clamp(0.0, 1.0),
        color: color,
      ),
    );
  }
}