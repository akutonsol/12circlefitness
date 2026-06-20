import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  final bool isLarge;

  const StreakBadge({super.key, required this.streak, this.isLarge = false});

  Color get _badgeColor {
    if (streak >= 30) return const Color(0xFFFFD700);
    if (streak >= 14) return const Color(0xFFC0C0C0);
    if (streak >= 7) return AppColors.purple;
    return AppColors.warning;
  }

  String get _badgeLabel {
    if (streak >= 30) return '🏆';
    if (streak >= 14) return '⭐';
    if (streak >= 7) return '💜';
    return '🔥';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 12 : 8, vertical: isLarge ? 6 : 4),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _badgeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_badgeLabel, style: TextStyle(fontSize: isLarge ? 16 : 12)),
          const SizedBox(width: 4),
          Text(
            '$streak days',
            style: TextStyle(color: _badgeColor, fontSize: isLarge ? 14 : 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
