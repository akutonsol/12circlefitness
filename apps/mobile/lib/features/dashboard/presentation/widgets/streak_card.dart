import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class StreakCard extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _glowController;
  late Animation<double> _flameScale;
  late Animation<double> _flameWobble;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _flameScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );

    _flameWobble = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flameController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.purple, AppColors.purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAnimatedFlame(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.currentStreak} Day Streak!',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0),
                const SizedBox(height: 4),
                Text(
                  'Longest: ${widget.longestStreak} days',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Keep going!',
              style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildAnimatedFlame() {
    return AnimatedBuilder(
      animation: Listenable.merge([_flameController, _glowController]),
      builder: (context, child) {
        return SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: _glowAnimation.value * 0.5),
                      blurRadius: 30,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
              // Flame emoji with animation
              Transform.scale(
                scale: _flameScale.value,
                child: Transform.rotate(
                  angle: _flameWobble.value,
                  child: const Text(
                    '🔥',
                    style: TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
