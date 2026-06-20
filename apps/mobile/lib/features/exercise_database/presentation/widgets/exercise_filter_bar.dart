import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_database_provider.dart';

class ExerciseFilterBar extends ConsumerWidget {
  const ExerciseFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(exerciseDatabaseServiceProvider);
    final selectedMuscle = ref.watch(selectedMuscleGroupProvider);
    final selectedEquipment = ref.watch(selectedEquipmentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Muscle Group', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: service.getMuscleGroups().map((muscle) {
              final isSelected = selectedMuscle == muscle;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ref.read(selectedMuscleGroupProvider.notifier).state = muscle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.purple : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.purple : AppColors.surfaceDarkElevated),
                    ),
                    child: Text(muscle, style: TextStyle(color: isSelected ? AppColors.white : AppColors.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Equipment', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: service.getEquipmentList().map((equipment) {
              final isSelected = selectedEquipment == equipment;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ref.read(selectedEquipmentProvider.notifier).state = equipment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.purple : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.purple : AppColors.surfaceDarkElevated),
                    ),
                    child: Text(equipment, style: TextStyle(color: isSelected ? AppColors.white : AppColors.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
