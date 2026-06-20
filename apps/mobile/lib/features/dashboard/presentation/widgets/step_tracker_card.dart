import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StepTrackerCard extends StatelessWidget {
  final int currentSteps;
  final int goalSteps;

  const StepTrackerCard({
    super.key,
    required this.currentSteps,
    required this.goalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentSteps / goalSteps;
    final percentage = (progress * 100).toInt();

    return Container(
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
              const Text('👟', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Steps',
                style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: const TextStyle(color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentSteps.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]},',
                ),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ $goalSteps',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceDarkElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
