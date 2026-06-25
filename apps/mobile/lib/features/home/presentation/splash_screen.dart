import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Onboarding screen 1 — the loading splash. The 12 Circle mark inside counter-
/// rotating loader arcs over a cinematic gym backdrop, with the FITNESS wordmark
/// and a "PREPARING YOUR TRAINING" progress bar that fills over ~5s, then advances
/// to screen 2.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFB06BFF);
const _pink        = Color(0xFFFF6BD6);

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spin;   // ring rotation + embers
  late final AnimationController _load;   // intro pop + progress bar
  late final Animation<double> _pop;
  late final Animation<double> _word;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _load = AnimationController(vsync: this, duration: const Duration(milliseconds: 4700))..forward();
    _pop      = CurvedAnimation(parent: _load, curve: const Interval(0.0, 0.2, curve: Curves.easeOutBack));
    _word     = CurvedAnimation(parent: _load, curve: const Interval(0.16, 0.4, curve: Curves.easeOut));
    _progress = CurvedAnimation(parent: _load, curve: const Interval(0.05, 1.0, curve: Curves.easeInOut));

    // ~5s on screen, then hand off to screen 2.
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060A),
      body: Stack(fit: StackFit.expand, children: [
        // Cinematic gym backdrop, dimmed.
        Opacity(opacity: 0.55, child: Image.asset('assets/images/splash1_bg.jpg',
          fit: BoxFit.cover, alignment: const Alignment(0, -0.1))),
        const DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.15), radius: 1.1,
            colors: [Color(0x8807060A), Color(0xDD07060A), Color(0xFF050409)],
            stops: [0.0, 0.6, 1.0]))),

        // Drifting embers.
        ..._embers(),

        // ── Center: loader arcs + 12 Circle mark + wordmark ──
        Align(
          alignment: const Alignment(0, -0.12),
          child: AnimatedBuilder(
            animation: Listenable.merge([_spin, _load]),
            builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 230, height: 230,
                child: Stack(alignment: Alignment.center, children: [
                  // spinning loader arcs
                  CustomPaint(size: const Size(230, 230), painter: _RingsPainter(_spin.value)),
                  // glowing 12 Circle mark
                  ScaleTransition(
                    scale: _pop,
                    child: Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: const Color(0xFFD36BFF).withValues(alpha: 0.25 + 0.3 * (math.sin(_spin.value * 2 * math.pi) + 1) / 2),
                          blurRadius: 40, spreadRadius: 4)]),
                      child: Image.asset('assets/images/12circle-fab.png', fit: BoxFit.contain),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 26),
              Opacity(
                opacity: _word.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _word.value) * 22),
                  child: Column(children: [
                    const Text('FITNESS', style: TextStyle(
                      color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: 12)),
                    const SizedBox(height: 8),
                    Text('STRENGTH IN NUMBERS', style: TextStyle(
                      color: _purpleLight.withValues(alpha: 0.95), fontSize: 12,
                      fontWeight: FontWeight.w700, letterSpacing: 5)),
                  ]),
                ),
              ),
            ]),
          ),
        ),

        // ── Bottom: loading label + progress bar ──
        Align(
          alignment: const Alignment(0, 0.88),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AnimatedBuilder(
              animation: _load,
              builder: (_, __) => Opacity(
                opacity: _word.value,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('PREPARING YOUR TRAINING', style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55), fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 3)),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(children: [
                      Container(height: 4, color: const Color(0x1AFFFFFF)),
                      FractionallySizedBox(
                        widthFactor: (0.06 + 0.94 * _progress.value).clamp(0.0, 1.0),
                        child: Container(height: 4, decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [_purple, _pink])))),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _embers() {
    const spec = [(0.16, 5.0, 0.0), (0.4, 3.5, 0.4), (0.66, 6.0, 0.7), (0.84, 4.0, 0.2)];
    return [
      for (final (x, sz, phase) in spec)
        AnimatedBuilder(
          animation: _spin,
          builder: (ctx, __) {
            final h = MediaQuery.of(ctx).size.height;
            final p = (_spin.value + phase) % 1.0;
            return Positioned(
              left: x * MediaQuery.of(ctx).size.width,
              top: h * (1 - p) - 30,
              child: Opacity(
                opacity: math.sin(p * math.pi) * 0.6,
                child: Container(width: sz, height: sz, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: const Color(0xFFE7C9FF),
                  boxShadow: [BoxShadow(color: _purpleLight.withValues(alpha: 0.6), blurRadius: 8)]))),
            );
          },
        ),
    ];
  }
}

/// Counter-rotating loader arcs that sweep around the 12 Circle mark.
class _RingsPainter extends CustomPainter {
  final double t;
  _RingsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final tau = 2 * math.pi;

    // Outer arc — purple/pink, clockwise.
    final outer = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: [_purple, _purpleLight, _pink])
          .createShader(Rect.fromCircle(center: c, radius: size.width * 0.5));
    canvas.drawArc(Rect.fromCircle(center: c, radius: size.width * 0.5),
      t * tau, tau * 0.5, false, outer);

    // Inner arc — pink, counter-clockwise.
    final inner = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round
      ..color = _pink.withValues(alpha: 0.8);
    canvas.drawArc(Rect.fromCircle(center: c, radius: size.width * 0.44),
      -t * tau * 1.4, tau * 0.28, false, inner);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}
