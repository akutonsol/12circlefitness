import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/exercise_detail_model.dart';

class ExerciseDetailCard extends StatelessWidget {
  final ExerciseDetail exercise;
  final VoidCallback onTap;

  const ExerciseDetailCard({super.key, required this.exercise, required this.onTap});

  Color _difficultyColor() {
    switch (exercise.difficulty.toLowerCase()) {
      case 'beginner': return AppColors.success;
      case 'intermediate': return AppColors.warning;
      case 'advanced': return AppColors.error;
      default: return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceDarkElevated),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center, color: AppColors.purple, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(exercise.muscleGroup, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag(exercise.equipment, AppColors.surfaceDarkElevated, AppColors.textTertiary),
                      const SizedBox(width: 6),
                      _buildTag(exercise.difficulty, _difficultyColor().withValues(alpha: 0.2), _difficultyColor()),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textTertiary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
