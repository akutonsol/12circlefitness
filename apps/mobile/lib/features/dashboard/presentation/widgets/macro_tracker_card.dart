import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MacroTrackerCard extends StatelessWidget {
  final Map<String, dynamic> macros;

  const MacroTrackerCard({super.key, required this.macros});

  @override
  Widget build(BuildContext context) {
    final calories = macros['calories'];
    final protein = macros['protein'];
    final carbs = macros['carbs'];
    final fat = macros['fat'];

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
              const Text('🥗', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Nutrition',
                style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${calories['current']} / ${calories['goal']} kcal',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (calories['current'] / calories['goal']).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceDarkElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMacro('Protein', protein['current'], protein['goal'], const Color(0xFF60A5FA)),
              const SizedBox(width: 12),
              _buildMacro('Carbs', carbs['current'], carbs['goal'], const Color(0xFFFBBF24)),
              const SizedBox(width: 12),
              _buildMacro('Fat', fat['current'], fat['goal'], const Color(0xFFF87171)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacro(String label, int current, int goal, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${current}g',
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (current / goal).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceDarkElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
