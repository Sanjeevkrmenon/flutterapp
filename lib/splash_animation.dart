// lib/splash_animation.dart

import 'dart:async';
import 'package:flutter/material.dart';

// Adjust as needed based on your pX.png and lX.png files
const int portraitFrames = 6;
const int landscapeFrames = 6;

class SplashAnimation extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashAnimation({required this.onFinish, Key? key}) : super(key: key);

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation> with SingleTickerProviderStateMixin {
  int _currentFrame = 1;
  late bool _isPortrait;

  // A single controller to manage the entire fade sequence (in, hold, out)
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // The total duration for the first frame's animation (fade in + hold + fade out)
    const totalDuration = Duration(milliseconds: 2900); // 1300ms fade-in + 700ms hold + 900ms fade-out

    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    // Create a sequence of tweens for the opacity
    _opacityAnimation = TweenSequence<double>([
      // 1. Fade In
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 1300, // Corresponds to the 1300ms fade-in duration
      ),
      // 2. Hold
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 700, // Corresponds to the 700ms hold duration
      ),
      // 3. Fade Out
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 900, // Corresponds to the 900ms fade-out duration
      ),
    ]).animate(_controller);

    // Start the animation sequence after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
  }

  /// Pre-caches all images for the current orientation to prevent flickering.
  Future<void> _precacheImages() async {
    if (!mounted) return;
    _isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    final imageProviders = _isPortrait
        ? List.generate(portraitFrames, (i) => AssetImage('assets/splash/portrait/p${i + 1}.png'))
        : List.generate(landscapeFrames, (i) => AssetImage('assets/splash/landscape/l${i + 1}.png'));

    for (final provider in imageProviders) {
      if (mounted) {
        await precacheImage(provider, context);
      }
    }
  }

  /// Runs the entire animation sequence.
  Future<void> _startSequence() async {
    // Ensure images are loaded into memory before starting to prevent flickers
    await _precacheImages();
    if (!mounted) return;

    // ----- 1. Animate Frame 1 (Fade In, Hold, Fade Out) -----
    setState(() => _currentFrame = 1);
    await _controller.forward(); // This runs the entire sequence defined in _opacityAnimation

    // ----- 2. Animate Subsequent Frames -----
    final frameCount = _isPortrait ? portraitFrames : landscapeFrames;
    for (int frame = 2; frame <= frameCount; frame++) {
      await Future.delayed(const Duration(milliseconds: 120)); // Quick delay between frames
      if (!mounted) return;
      setState(() => _currentFrame = frame);
    }

    // ----- 3. Final Delay & Finish -----
    await Future.delayed(const Duration(milliseconds: 320));
    if (mounted) {
      widget.onFinish();
    }
  }

  /// Returns the asset path for the current frame and orientation.
  String _framePath() {
    final prefix = _isPortrait ? 'p' : 'l';
    final folder = _isPortrait ? 'portrait' : 'landscape';
    return "assets/splash/$folder/$prefix$_currentFrame.png";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The check for mounted ensures we don't try to access context after dispose()
    if (!mounted) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _currentFrame == 1
        // --- The "PARABOT" Frame (animated with FadeTransition) ---
            ? FadeTransition(
          opacity: _opacityAnimation,
          child: Image.asset(
            _framePath(),
            width: 340,
            height: 340,
            fit: BoxFit.contain,
            gaplessPlayback: true, // Helps prevent flicker on image change
          ),
        )
        // --- All other frames (just swap images) ---
            : Image.asset(
          _framePath(),
          width: 340,
          height: 340,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}