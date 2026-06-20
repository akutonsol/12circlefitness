import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static void hapticLight() {
    HapticFeedback.lightImpact();
  }

  static void hapticMedium() {
    HapticFeedback.mediumImpact();
  }

  static void hapticHeavy() {
    HapticFeedback.heavyImpact();
  }

  static void hapticSuccess() {
    HapticFeedback.selectionClick();
  }
}

extension AnimateExtensions on Widget {
  Widget fadeSlideIn({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget fadeIn({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .fadeIn(duration: 300.ms, curve: Curves.easeOut);
  }

  Widget scaleIn({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }

  Widget slideInFromRight({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .slideX(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 400.ms);
  }

  Widget slideInFromLeft({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .slideX(begin: -0.3, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 400.ms);
  }

  Widget pulse() {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1000.ms);
  }

  Widget shimmer() {
    return animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white24);
  }
}

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 80),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        return entry.value.fadeSlideIn(delay: staggerDelay * entry.key);
      }).toList(),
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;

  const AnimatedCounter({super.key, required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, val, child) => Text(val.toString(), style: style),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;
  final Color backgroundColor;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
    this.backgroundColor = const Color(0xFF2A2A2A),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: height,
        ),
      ),
    );
  }
}

class CompletionOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const CompletionOverlay({super.key, required this.onComplete});

  @override
  State<CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<CompletionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _controller.forward().then((_) => widget.onComplete());
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _controller.value < 0.8 ? 1.0 : (1.0 - (_controller.value - 0.8) / 0.2),
        child: Center(
          child: Transform.scale(
            scale: 0.5 + (_controller.value * 0.5),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 10)],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}
