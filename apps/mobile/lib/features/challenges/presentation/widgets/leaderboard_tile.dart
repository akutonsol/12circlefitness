import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/challenge_model.dart';

class LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int index;

  const LeaderboardTile({super.key, required this.entry, required this.index});

  Color get _rankColor {
    switch (entry.rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return AppColors.textTertiary;
    }
  }

  String get _rankEmoji {
    switch (entry.rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#${entry.rank}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isMe ? AppColors.purple.withValues(alpha: 0.15) : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isMe ? AppColors.purple.withValues(alpha: 0.4) : AppColors.surfaceDarkElevated,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: entry.rank <= 3
                ? Text(_rankEmoji, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)
                : Text('#${entry.rank}',
                    style: TextStyle(color: _rankColor, fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: entry.isMe ? AppColors.purple : AppColors.purple.withValues(alpha: 0.2),
            child: Text(
              entry.userName[0],
              style: TextStyle(
                color: entry.isMe ? AppColors.white : AppColors.purple,
                fontSize: 14, fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.isMe ? 'You' : entry.userName,
                      style: TextStyle(
                        color: entry.isMe ? AppColors.purple : AppColors.white,
                        fontSize: 14, fontWeight: entry.isMe ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (entry.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('You', style: TextStyle(color: AppColors.purple, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.progress,
                    backgroundColor: AppColors.surfaceDarkElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      entry.rank == 1 ? const Color(0xFFFFD700) : entry.isMe ? AppColors.purple : AppColors.textSecondary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            entry.score.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
            style: TextStyle(
              color: entry.isMe ? AppColors.purple : AppColors.white,
              fontSize: 13, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: entry.isMe ? 0.2 : -0.1, end: 0, duration: 300.ms);
  }
}
