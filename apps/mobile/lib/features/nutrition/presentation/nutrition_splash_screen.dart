import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../coaching_mode/domain/coaching_mode_provider.dart';

const _bg      = Color(0xFF030303);
const _brand   = Color(0xFFA855F7);
const _white   = Colors.white;
const _muted   = Color(0xFFCFC2D6);
const _primary = Color(0xFFDDB7FF);

/// Gateway screen for the Nutrition section.
/// Routes based on coaching mode:
///   AI-Guided   → /ai-nutrition   (AI-powered meal planning + chat)
///   Coach-Guided→ /meals-dashboard (standard logs, coach sees everything)
///   Self-Guided → /meals-dashboard (standard logs)
class NutritionSplashScreen extends ConsumerStatefulWidget {
  const NutritionSplashScreen({super.key});

  @override
  ConsumerState<NutritionSplashScreen> createState() =>
      _NutritionSplashScreenState();
}

class _NutritionSplashScreenState extends ConsumerState<NutritionSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final mode = ref.read(coachingModeProvider);
      if (mode == CoachingMode.aiGuided) {
        context.go('/ai-nutrition');
      } else {
        context.go('/meals-dashboard');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(coachingModeProvider);
    final isAI = mode == CoachingMode.aiGuided;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  final scale = 1.0 + (_controller.value * 0.12);
                  final glow  = 0.25 + (_controller.value * 0.35);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isAI
                            ? [const Color(0xFF06B6D4), const Color(0xFFA855F7)]
                            : [_brand, _primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                        boxShadow: [
                          BoxShadow(
                            color: (isAI ? const Color(0xFF06B6D4) : _brand)
                                .withValues(alpha: glow),
                            blurRadius: 32, spreadRadius: 4),
                        ]),
                      child: Icon(
                        isAI ? Icons.auto_awesome : Icons.eco,
                        color: _white, size: 44)));
                }),
              const SizedBox(height: 28),
              Text(
                isAI ? 'AI Nutrition Coach' : 'Personalised Nutrition',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _white, fontSize: 22,
                  fontWeight: FontWeight.w800, height: 1.3)),
              const SizedBox(height: 10),
              Text(
                isAI
                  ? 'Your AI coach is preparing your\npersonalised meal plan…'
                  : 'Loading your meal tracker…',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 13)),

              if (isAI) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.2))),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF06B6D4), size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'AI-Guided mode: meal plans, macro targets & smart suggestions',
                      style: TextStyle(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.9),
                        fontSize: 11, height: 1.4))),
                  ])),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: 36, height: 36,
                child: CircularProgressIndicator(
                  color: isAI ? const Color(0xFF06B6D4) : _primary,
                  strokeWidth: 2.5)),
            ],
          ),
        ),
      ),
    );
  }
}
