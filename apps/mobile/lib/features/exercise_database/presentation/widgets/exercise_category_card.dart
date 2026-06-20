import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ExerciseCategoryCard extends StatelessWidget {
  final String category;
  final int count;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ExerciseCategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.purple : AppColors.surfaceDarkElevated,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white.withValues(alpha: 0.2) : AppColors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? AppColors.white : AppColors.purple, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$count exercises',
              style: TextStyle(
                color: isSelected ? AppColors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
