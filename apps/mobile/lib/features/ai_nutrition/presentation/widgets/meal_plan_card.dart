import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MealPlanCard extends StatelessWidget {
  final String dayTitle;
  final List<Map<String, String>> meals;

  const MealPlanCard({
    super.key,
    required this.dayTitle,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceDarkElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dayTitle,
              style: const TextStyle(color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          ...meals.map((meal) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    meal['type'] ?? '',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    meal['meal'] ?? '',
                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                ),
                if (meal['calories'] != null)
                  Text(
                    meal['calories']!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
