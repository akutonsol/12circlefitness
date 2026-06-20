import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/food_model.dart';

class FoodItemCard extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const FoodItemCard({super.key, required this.food, required this.onTap});

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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_outlined, color: AppColors.purple, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(food.brand, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Per ${food.servingSize.toInt()}${food.servingUnit}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${food.calories.toInt()} kcal', style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMacro('P ${food.protein.toInt()}g', const Color(0xFF60A5FA)),
                    const SizedBox(width: 4),
                    _buildMacro('C ${food.carbs.toInt()}g', const Color(0xFFFBBF24)),
                    const SizedBox(width: 4),
                    _buildMacro('F ${food.fat.toInt()}g', const Color(0xFFF87171)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacro(String label, Color color) {
    return Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500));
  }
}
