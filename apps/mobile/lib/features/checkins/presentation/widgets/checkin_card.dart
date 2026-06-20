import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/checkin_model.dart';
import '../../domain/checkin_provider.dart';
import 'checkin_status_badge.dart';

class CheckinCard extends ConsumerWidget {
  final WeeklyCheckin checkin;
  final int index;

  const CheckinCard({super.key, required this.checkin, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = checkin.status == CheckinStatus.pending;
    final isReviewed = checkin.status == CheckinStatus.reviewed;

    return GestureDetector(
      onTap: () {
        ref.read(selectedCheckinProvider.notifier).state = checkin;
        if (isPending) {
          context.push('/checkin-form');
        } else {
          context.push('/checkin-detail');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPending ? AppColors.warning.withValues(alpha: 0.1) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPending ? AppColors.warning.withValues(alpha: 0.3) : AppColors.surfaceDarkElevated,
          ),
          boxShadow: isPending
              ? [BoxShadow(color: AppColors.warning.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week ${checkin.weekNumber}',
                      style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(checkin.weekStartDate),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                CheckinStatusBadge(status: checkin.status),
              ],
            ),
            if (isReviewed && checkin.overallScore > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildScoreIndicator(checkin.overallScore),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall Score', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: checkin.overallScore / 10,
                          backgroundColor: AppColors.surfaceDarkElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(checkin.overallScore)),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (checkin.feedback != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.purple,
                        child: Icon(Icons.person, color: AppColors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          checkin.feedback!.message,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  const Text('Your weekly check-in is ready!', style: TextStyle(color: AppColors.warning, fontSize: 13)),
                  const Spacer(),
                  const Text('Start →', style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildScoreIndicator(double score) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _scoreColor(score).withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          score.toStringAsFixed(1),
          style: TextStyle(color: _scoreColor(score), fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
