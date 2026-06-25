import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Cinematic animated backdrop from the 12 Circle Home design: slow-cycling hero
/// photos with a ken-burns drift, purple/pink ambient glow, drifting embers, and
/// a heavy dark gradient so foreground content stays legible.
class CinematicBackdrop extends StatefulWidget {
  final List<String> images;
  final double overlayStrength; // 0..1 darkness of the bottom wash
  const CinematicBackdrop({
    super.key,
    this.overlayStrength = 1,
    this.images = const [
      'assets/images/home_bg_gym.jpg',
      'assets/images/splash_hero1.jpg',
      'assets/images/splash_hero2.jpg',
    ],
  });
  @override
  State<CinematicBackdrop> createState() => _CinematicBackdropState();
}

class _CinematicBackdropState extends State<CinematicBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _cycle;   // image cross-fade
  late final AnimationController _drift;   // ken burns + embers

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(vsync: this, duration: Duration(seconds: 7 * widget.images.length))..repeat();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _cycle.dispose();
    _drift.dispose();
    super.dispose();
  }

  // Smoothly cross-fade between consecutive images (wrapping).
  double _opacity(int i, int n, double t) {
    final center = i / n;
    var d = (t - center).abs();
    d = math.min(d, 1 - d);
    return (1 - (d / (1.0 / n))).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.images.length;
    final o = widget.overlayStrength;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_cycle, _drift]),
        builder: (_, __) {
          final t = _cycle.value;
          final kb = 1.08 + 0.10 * (math.sin(_drift.value * 2 * math.pi) + 1) / 2;
          return Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xFF050608)),
            // Cycling hero photos.
            for (var i = 0; i < n; i++)
              Opacity(
                opacity: _opacity(i, n, t),
                child: Transform.scale(
                  scale: kb,
                  child: Image.asset(widget.images[i], fit: BoxFit.cover,
                    alignment: const Alignment(0.3, -0.2), gaplessPlayback: true)),
              ),
            // Ambient purple/pink glow.
            Align(
              alignment: const Alignment(0.7, -0.5),
              child: Container(width: 360, height: 360, decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.purple.withValues(alpha: 0.28), Colors.transparent])))),
            const Align(
              alignment: Alignment(-0.8, 0.4),
              child: _Glow(color: Color(0xFFFF9FC4), size: 280, alpha: 0.14)),
            // Drifting embers.
            ..._embers(),
            // Heavy dark gradient for legibility.
            DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(Colors.transparent, const Color(0xFF050608), 0.35 * o)!,
                  Color.lerp(Colors.transparent, const Color(0xFF080611), 0.78 * o)!,
                  Color.lerp(Colors.transparent, const Color(0xFF050608), 0.94 * o)!,
                ],
                stops: const [0.0, 0.5, 1.0]))),
          ]);
        },
      ),
    );
  }

  List<Widget> _embers() {
    const spec = [(0.18, 5.0, 0.0), (0.42, 3.5, 0.35), (0.7, 6.0, 0.6), (0.86, 4.0, 0.15)];
    return [
      for (final (x, sz, phase) in spec)
        Builder(builder: (ctx) {
          final h = MediaQuery.of(ctx).size.height;
          final p = (_drift.value + phase) % 1.0;
          return Positioned(
            left: x * MediaQuery.of(ctx).size.width,
            top: h * (1 - p) - 40,
            child: Opacity(
              opacity: (math.sin(p * math.pi)) * 0.7,
              child: Container(width: sz, height: sz, decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE7C9FF),
                boxShadow: [BoxShadow(color: AppColors.purpleLight.withValues(alpha: 0.6), blurRadius: 8)]))),
          );
        }),
    ];
  }
}

class _Glow extends StatelessWidget {
  final Color color; final double size; final double alpha;
  const _Glow({required this.color, required this.size, required this.alpha});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size, decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withValues(alpha: alpha), Colors.transparent])));
}
