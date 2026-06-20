import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/progress_model.dart';

class MeasurementCard extends StatelessWidget {
  final BodyMeasurement current;
  final BodyMeasurement? previous;

  const MeasurementCard({super.key, required this.current, this.previous});

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Body Measurements', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${current.loggedAt.day}/${current.loggedAt.month}/${current.loggedAt.year}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMeasurementTile('Chest', current.chest, previous?.chest, '👚'),
              _buildMeasurementTile('Waist', current.waist, previous?.waist, '📏'),
              _buildMeasurementTile('Hips', current.hips, previous?.hips, '🍑'),
              _buildMeasurementTile('Thighs', current.thighs, previous?.thighs, '🦵'),
              _buildMeasurementTile('Arms', current.arms, previous?.arms, '💪'),
              _buildMeasurementTile('Shoulders', current.shoulders, previous?.shoulders, '🏋️'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTile(String label, double? current, double? previous, String emoji) {
    final change = (current != null && previous != null) ? current - previous : null;
    final isImprovement = change != null && change < 0;
    final isIncrease = change != null && change > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                Row(
                  children: [
                    Text(
                      current != null ? '${current.toInt()}cm' : '-',
                      style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (change != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: isImprovement ? AppColors.success : isIncrease ? AppColors.error : AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
