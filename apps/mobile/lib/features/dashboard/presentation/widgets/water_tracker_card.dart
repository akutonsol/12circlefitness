import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/dashboard_provider.dart';

class WaterTrackerCard extends ConsumerWidget {
  const WaterTrackerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(waterIntakeProvider);
    const goal = 8;

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
              const Text('💧', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Water Intake',
                style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$current / $goal glasses',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(goal, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(waterIntakeProvider.notifier).state = index + 1;
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: index < current
                            ? const Color(0xFF38BDF8)
                            : AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: index < current
                          ? const Icon(Icons.water_drop, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: current / goal,
              backgroundColor: AppColors.surfaceDarkElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
