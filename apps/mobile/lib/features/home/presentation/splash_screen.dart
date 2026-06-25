import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Onboarding launch splash — the Splash-standalone design. Spinning purple/pink
/// loader arcs around a "12" over a deep purple→black wash with a soft glow and
/// drifting embers, the 12 CIRCLE / STRENGTH IN NUMBERS wordmark, then advances
/// to the welcome screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

const _purple      = Color(0xFF8A3DF0);
const _purpleLight = Color(0xFFB06BFF);
const _pink        = Color(0xFFFF4D8D);
const _twelve      = Color(0xFFC9B0FF);

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spin;   // ring rotation + embers
  late final AnimationController _intro;  // pop + wordmark reveal
  late final Animation<double> _pop;
  late final Animation<double> _word;

  @override
  void initState() {
    super.initState();
    _spin  = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _pop  = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack));
    _word = CurvedAnimation(parent: _intro, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060409),
      body: Stack(fit: StackFit.expand, children: [
        // Deep purple → black wash.
        const DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1030), Color(0xFF0C0815), Color(0xFF060409)],
            stops: [0.0, 0.5, 1.0]))),
        // Soft purple glow behind the mark.
        const Align(alignment: Alignment(0, 0.18),
          child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(radius: 0.6,
              colors: [Color(0x3A8A3DF0), Color(0x000C0815)])),
            child: SizedBox(width: 520, height: 520))),

        // Drifting embers.
        ..._embers(),

        // ── Center: loader arcs + 12, wordmark below ──
        Align(
          alignment: const Alignment(0, 0.12),
          child: AnimatedBuilder(
            animation: Listenable.merge([_spin, _intro]),
            builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
              ScaleTransition(
                scale: _pop,
                child: SizedBox(
                  width: 210, height: 210,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(size: const Size(210, 210), painter: _RingsPainter(_spin.value)),
                    Text('12', style: TextStyle(
                      color: _twelve, fontSize: 54, fontWeight: FontWeight.w800, letterSpacing: -1,
                      shadows: [Shadow(color: _purpleLight.withValues(alpha: 0.6), blurRadius: 18)])),
                  ]),
                ),
              ),
              const SizedBox(height: 40),
              Opacity(
                opacity: _word.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _word.value) * 20),
                  child: Column(children: [
                    const Text('12 CIRCLE', style: TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 10)),
                    const SizedBox(height: 10),
                    Text('STRENGTH IN NUMBERS', style: TextStyle(
                      color: _purpleLight.withValues(alpha: 0.92), fontSize: 12,
                      fontWeight: FontWeight.w700, letterSpacing: 5)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  List<Widget> _embers() {
    const spec = [(0.16, 4.0, 0.0), (0.4, 3.0, 0.4), (0.66, 5.0, 0.7), (0.84, 3.5, 0.2)];
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
                opacity: math.sin(p * math.pi) * 0.5,
                child: Container(width: sz, height: sz, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: const Color(0xFFE7C9FF),
                  boxShadow: [BoxShadow(color: _purpleLight.withValues(alpha: 0.6), blurRadius: 8)]))),
            );
          },
        ),
    ];
  }
}

/// Concentric spinning loader arcs — purple outer + pink accents, per the design.
class _RingsPainter extends CustomPainter {
  final double t;
  _RingsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const tau = 2 * math.pi;
    final rOuter = size.width * 0.46;
    final rInner = size.width * 0.34;

    // Outer arc — purple→pink gradient, ~3/4 turn, clockwise.
    canvas.drawArc(Rect.fromCircle(center: c, radius: rOuter), t * tau, tau * 0.74, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(colors: [_purple, _purpleLight, _pink, _purple])
            .createShader(Rect.fromCircle(center: c, radius: rOuter)));

    // Bright pink accent arc on the outer radius, faster.
    canvas.drawArc(Rect.fromCircle(center: c, radius: rOuter), -t * tau * 1.7, tau * 0.16, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round
        ..color = _pink);

    // Inner arc — pink, ~0.7 turn, counter-clockwise.
    canvas.drawArc(Rect.fromCircle(center: c, radius: rInner), -t * tau * 1.3, tau * 0.7, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round
        ..color = _pink.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}
