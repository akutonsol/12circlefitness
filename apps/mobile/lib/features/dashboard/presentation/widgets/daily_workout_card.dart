import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DailyWorkoutCard extends StatelessWidget {
  final String title;
  final int duration;
  final int calories;
  final bool completed;
  final double progress;
  final VoidCallback onTap;

  const DailyWorkoutCard({
    super.key,
    required this.title,
    required this.duration,
    required this.calories,
    required this.completed,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceDarkElevated),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppColors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Workout',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: completed ? AppColors.success.withValues(alpha: 0.2) : AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    completed ? 'Done ✓' : 'Start',
                    style: TextStyle(
                      color: completed ? AppColors.success : AppColors.purple,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.textTertiary, size: 16),
                const SizedBox(width: 4),
                Text('$duration min', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.local_fire_department_outlined, color: AppColors.textTertiary, size: 16),
                const SizedBox(width: 4),
                Text('$calories kcal', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceDarkElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
