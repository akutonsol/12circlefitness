import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// Cinematic launch splash: cross-fading hero photos with a slow ken-burns drift,
/// a purple glow, and the "12 CIRCLE / FITNESS" wordmark — then hands off to the
/// router's auth redirect.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _hero;   // cross-fade + ken burns loop
  late final AnimationController _intro;  // wordmark + glow reveal

  late final Animation<double> _wordFade;
  late final Animation<double> _wordSlide;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _hero = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
    _wordFade  = CurvedAnimation(parent: _intro, curve: const Interval(0.25, 0.7, curve: Curves.easeOut));
    _wordSlide = CurvedAnimation(parent: _intro, curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic));
    _glow      = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _hero.dispose();
    _intro.dispose();
    super.dispose();
  }

  Widget get _hero1 => Image.asset('assets/images/splash_hero1.jpg',
    fit: BoxFit.cover, alignment: const Alignment(0.5, -0.35), gaplessPlayback: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: AnimatedBuilder(
        animation: Listenable.merge([_hero, _intro]),
        builder: (_, __) {
          // 0..1 cross-fade between the two heroes, smooth in both directions.
          final cross = (math.sin(_hero.value * 2 * math.pi - math.pi / 2) + 1) / 2;
          final kb = 1.06 + 0.06 * (math.sin(_hero.value * 2 * math.pi) + 1) / 2; // ken burns
          return Stack(fit: StackFit.expand, children: [
            // Hero 1 (always under)
            Transform.scale(scale: kb, child: _hero1),
            // Hero 2 (cross-fades over)
            Opacity(
              opacity: cross,
              child: Transform.scale(
                scale: 1.04 + (1.10 - 1.04) * (1 - cross),
                child: Image.asset('assets/images/splash_hero2.jpg',
                  fit: BoxFit.cover, alignment: const Alignment(0, -0.15), gaplessPlayback: true)),
            ),
            // Dark + purple wash for legibility and brand glow.
            const DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0x00050608), Color(0x66050608), Color(0xF2050608)],
                stops: [0.0, 0.45, 0.92]))),
            // Purple radial glow behind the wordmark.
            Align(
              alignment: const Alignment(0, 0.42),
              child: Opacity(
                opacity: 0.55 * _glow.value,
                child: Container(width: 320, height: 320, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.purple.withValues(alpha: 0.45), Colors.transparent])))),
            ),

            // Wordmark + loading.
            Align(
              alignment: const Alignment(0, 0.5),
              child: Opacity(
                opacity: _wordFade.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _wordSlide.value) * 20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('12 CIRCLE', style: TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 7)),
                    const SizedBox(height: 6),
                    Text('FITNESS', style: TextStyle(
                      color: AppColors.purpleLight, fontSize: 13,
                      fontWeight: FontWeight.w600, letterSpacing: 11)),
                  ]),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.86),
              child: Opacity(
                opacity: _wordFade.value,
                child: SizedBox(width: 110, child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    minHeight: 3, backgroundColor: Color(0x1AFFFFFF),
                    valueColor: AlwaysStoppedAnimation(AppColors.purpleLight)))),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
