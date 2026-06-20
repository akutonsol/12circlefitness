import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class UpcomingClassCard extends StatelessWidget {
  final String title;
  final String coach;
  final String time;
  final String date;
  final int spots;

  const UpcomingClassCard({
    super.key,
    required this.title,
    required this.coach,
    required this.time,
    required this.date,
    required this.spots,
  });

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
            children: [
              const Text('🏋️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Upcoming Class',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text(coach, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: AppColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text('$date • $time', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$spots spots left',
                  style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Book', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
