import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/animations/app_animations.dart';
import '../../data/models/habit_model.dart';
import '../../domain/habit_provider.dart';
import 'streak_badge.dart';
import 'habit_progress_ring.dart';

class HabitCard extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard> {
  bool _showCompletion = false;

  Color get _categoryColor {
    switch (widget.habit.category) {
      case HabitCategory.health: return const Color(0xFF38BDF8);
      case HabitCategory.fitness: return AppColors.purple;
      case HabitCategory.nutrition: return const Color(0xFF34D399);
      case HabitCategory.mindfulness: return const Color(0xFFA78BFA);
      case HabitCategory.sleep: return const Color(0xFF60A5FA);
    }
  }

  void _onComplete() {
    setState(() => _showCompletion = true);
    AppAnimations.hapticSuccess();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showCompletion = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSimple = widget.habit.targetValue == 1;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.habit.isCompletedToday ? _categoryColor.withValues(alpha: 0.1) : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.habit.isCompletedToday ? _categoryColor.withValues(alpha: 0.3) : AppColors.surfaceDarkElevated,
            ),
            boxShadow: widget.habit.isCompletedToday
                ? [BoxShadow(color: _categoryColor.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HabitProgressRing(
                    progress: widget.habit.progress,
                    size: 52,
                    color: _categoryColor,
                    child: Text(widget.habit.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.habit.name, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            '${widget.habit.currentValue} / ${widget.habit.targetValue} ${widget.habit.unit}',
                            key: ValueKey(widget.habit.currentValue),
                            style: TextStyle(color: _categoryColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.habit.isCompletedToday)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: AppColors.white, size: 18),
                    ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
                  else if (isSimple)
                    GestureDetector(
                      onTap: () {
                        ref.read(liveHabitNotifierProvider.notifier).toggleComplete(widget.habit.id);
                        _onComplete();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.textTertiary),
                        ),
                        child: const Icon(Icons.check, color: AppColors.textTertiary, size: 18),
                      ),
                    ),
                ],
              ),
              if (!isSimple) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreakBadge(streak: widget.habit.currentStreak),
                    Row(
                      children: [
                        const Icon(Icons.swipe_outlined, color: AppColors.textTertiary, size: 14),
                        const SizedBox(width: 4),
                        const Text('Slide to update', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _categoryColor,
                    inactiveTrackColor: AppColors.surfaceDarkElevated,
                    thumbColor: _categoryColor,
                    overlayColor: _categoryColor.withValues(alpha: 0.2),
                    thumbShape: _CustomThumbShape(color: _categoryColor),
                    trackHeight: 8,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: widget.habit.currentValue.toDouble(),
                    min: 0,
                    max: widget.habit.targetValue.toDouble(),
                    divisions: widget.habit.targetValue,
                    onChanged: (value) {
                      AppAnimations.hapticLight();
                      ref.read(liveHabitNotifierProvider.notifier).updateValue(widget.habit.id, value.toInt());
                    },
                    onChangeEnd: (value) {
                      if (value >= widget.habit.targetValue) _onComplete();
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                StreakBadge(streak: widget.habit.currentStreak),
              ],
            ],
          ),
        ),
        if (_showCompletion)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CompletionOverlay(onComplete: () {}),
            ),
          ),
      ],
    );
  }
}

class _CustomThumbShape extends SliderComponentShape {
  final Color color;

  const _CustomThumbShape({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
    final gripPaint = Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.fill;

    canvas.drawCircle(center, 12, fillPaint);
    canvas.drawCircle(center, 12, borderPaint);
    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(center.dx + (i * 4), center.dy), 1.5, gripPaint);
    }
  }
}
