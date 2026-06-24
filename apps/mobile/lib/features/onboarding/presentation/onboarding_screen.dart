import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
class _C {
  static const purple      = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFF9F67FF);
  static const purpleDark  = Color(0xFF5B21B6);
  static const muted       = Color(0xFFCFC2D6);
}

/// Single animated welcome screen. Plays a brand intro, then reveals the
/// Get Started CTA (→ signup) and a Sign in link (→ login).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;

  // Each element fades/slides in over its own slice of the intro.
  Animation<double> _at(double start, double end, {Curve curve = Curves.easeOut}) =>
      CurvedAnimation(parent: _intro, curve: Interval(start, end, curve: curve));

  static const _features = [
    (Icons.fitness_center_rounded, 'Train', 'World-class programming'),
    (Icons.restaurant_rounded, 'Fuel', 'Precision nutrition coaching'),
    (Icons.self_improvement_rounded, 'Recover', 'Recovery & wellness tracking'),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Widget _fadeUp(Animation<double> a, Widget child, {double dy = 18}) =>
      AnimatedBuilder(
        animation: a,
        builder: (_, c) => Opacity(
          opacity: a.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - a.value) * dy), child: c)),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final badgeScale = _at(0.0, 0.40, curve: Curves.easeOutBack);
    final badgeFade  = _at(0.0, 0.28);
    final word       = _at(0.32, 0.58);
    final tagline    = _at(0.50, 0.72);
    final cta        = _at(0.78, 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35), radius: 1.2,
            colors: [Color(0xFF1B2238), Color(0xFF0B1326), Color(0xFF060A14)],
            stops: [0.0, 0.55, 1.0])),
        child: SafeArea(
          child: Stack(children: [
            // Pulse rings behind the badge (upper area).
            Align(
              alignment: const Alignment(0, -0.55),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => CustomPaint(
                  size: const Size(300, 300), painter: _PulsePainter(_pulse.value)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(children: [
                const Spacer(flex: 3),

                // Badge
                ScaleTransition(
                  scale: badgeScale,
                  child: FadeTransition(
                    opacity: badgeFade,
                    child: Container(
                      width: 104, height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_C.purpleLight, _C.purpleDark],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        boxShadow: [BoxShadow(color: _C.purple.withValues(alpha: 0.55),
                          blurRadius: 40, spreadRadius: 2)]),
                      child: const Center(child: Text('12', style: TextStyle(
                        color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800,
                        letterSpacing: -1)))),
                  ),
                ),
                const SizedBox(height: 26),

                // Wordmark
                _fadeUp(word, const Column(children: [
                  Text('12 CIRCLE', style: TextStyle(color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w800, letterSpacing: 6)),
                  SizedBox(height: 6),
                  Text('FITNESS', style: TextStyle(color: _C.purpleLight, fontSize: 13,
                    fontWeight: FontWeight.w600, letterSpacing: 10)),
                ])),
                const SizedBox(height: 18),

                // Tagline
                _fadeUp(tagline, const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Train smarter. Eat better. Recover deeper.\nYour complete fitness ecosystem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _C.muted, fontSize: 14, height: 1.5)))),

                const Spacer(flex: 2),

                // Feature highlights stagger in.
                ...List.generate(_features.length, (i) {
                  final f = _features[i];
                  final a = _at(0.58 + i * 0.06, 0.80 + i * 0.06);
                  return _fadeUp(a, Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: _C.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.purple.withValues(alpha: 0.3))),
                        child: Icon(f.$1, color: _C.purpleLight, size: 20)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.$2.toUpperCase(), style: const TextStyle(color: _C.purpleLight,
                          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(f.$3, style: const TextStyle(color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w600)),
                      ])),
                    ])));
                }),

                const Spacer(flex: 2),

                // CTA — revealed when the intro finishes.
                _fadeUp(cta, Column(children: [
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Get Started', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text.rich(TextSpan(children: [
                      TextSpan(text: 'Already have an account?  ',
                        style: TextStyle(color: _C.muted, fontSize: 13)),
                      TextSpan(text: 'Sign in',
                        style: TextStyle(color: _C.purpleLight, fontSize: 13,
                          fontWeight: FontWeight.w700)),
                    ])),
                  ),
                ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Concentric rings expanding outward and fading.
class _PulsePainter extends CustomPainter {
  final double t;
  _PulsePainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const rings = 3;
    final maxR = size.width / 2;
    const baseR = 52.0;
    for (var i = 0; i < rings; i++) {
      final p = (t + i / rings) % 1.0;
      final radius = baseR + p * (maxR - baseR);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _C.purpleLight.withValues(alpha: (1.0 - p) * 0.30);
      canvas.drawCircle(center, radius, paint);
    }
  }
  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t;
}
