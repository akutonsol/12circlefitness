import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// Branded animated launch splash. Pulse rings radiate from a "12" badge that
/// scales in, then the wordmark fades up — before handing off to the router's
/// auth redirect.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;

  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeFade;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

    _badgeScale = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack));
    _badgeFade  = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.30, curve: Curves.easeOut));
    _textFade   = CurvedAnimation(parent: _intro, curve: const Interval(0.40, 0.75, curve: Curves.easeOut));
    _textSlide  = CurvedAnimation(parent: _intro, curve: const Interval(0.40, 0.80, curve: Curves.easeOutCubic));

    // Hand off to the router (which redirects to the right place by auth/role).
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, radius: 1.1,
            colors: [Color(0xFF1B2238), Color(0xFF0B1326), Color(0xFF060A14)],
            stops: [0.0, 0.55, 1.0])),
        child: Stack(children: [
          // Pulse rings behind the badge.
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => CustomPaint(
                size: const Size(320, 320),
                painter: _PulsePainter(_pulse.value)),
            ),
          ),
          // Badge + wordmark.
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ScaleTransition(
                scale: _badgeScale,
                child: FadeTransition(
                  opacity: _badgeFade,
                  child: Container(
                    width: 108, height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.purpleLight, AppColors.purpleDark],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(color: AppColors.purple.withValues(alpha: 0.55),
                          blurRadius: 40, spreadRadius: 2),
                      ]),
                    child: const Center(
                      child: Text('12', style: TextStyle(
                        color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800,
                        letterSpacing: -1)))),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _textFade,
                child: AnimatedBuilder(
                  animation: _textSlide,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, (1 - _textSlide.value) * 16), child: child),
                  child: Column(children: [
                    const Text('12 CIRCLE', style: TextStyle(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800,
                      letterSpacing: 6)),
                    const SizedBox(height: 6),
                    Text('FITNESS', style: TextStyle(
                      color: AppColors.purpleLight.withValues(alpha: 0.9), fontSize: 13,
                      fontWeight: FontWeight.w600, letterSpacing: 10)),
                  ]),
                ),
              ),
            ]),
          ),
          // Loading shimmer at the bottom.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: FadeTransition(
                opacity: _textFade,
                child: SizedBox(
                  width: 120,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(AppColors.purpleLight),
                        value: null)),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Three concentric rings that expand outward and fade, staggered over time.
class _PulsePainter extends CustomPainter {
  final double t; // 0..1 looping
  _PulsePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const rings = 3;
    final maxR = size.width / 2;
    const baseR = 54.0;
    for (var i = 0; i < rings; i++) {
      final p = (t + i / rings) % 1.0;
      final radius = baseR + p * (maxR - baseR);
      final opacity = (1.0 - p) * 0.35;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.purpleLight.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t;
}
