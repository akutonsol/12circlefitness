import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/animations/app_animations.dart';
import '../../data/models/challenge_model.dart';
import '../../domain/challenge_provider.dart';

class ChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  final int index;

  const ChallengeCard({super.key, required this.challenge, required this.index});

  Color get _statusColor {
    switch (challenge.status) {
      case ChallengeStatus.active: return AppColors.success;
      case ChallengeStatus.upcoming: return AppColors.warning;
      case ChallengeStatus.completed: return AppColors.textTertiary;
    }
  }

  String get _statusLabel {
    switch (challenge.status) {
      case ChallengeStatus.active: return 'Active';
      case ChallengeStatus.upcoming: return 'Starting Soon';
      case ChallengeStatus.completed: return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedChallengeProvider.notifier).state = challenge;
        context.push('/challenge-detail');
        AppAnimations.hapticLight();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: challenge.isJoined && challenge.status == ChallengeStatus.active
                ? AppColors.purple.withValues(alpha:0.3)
                : AppColors.surfaceDarkElevated,
          ),
          boxShadow: challenge.isJoined && challenge.status == ChallengeStatus.active
              ? [BoxShadow(color: AppColors.purple.withValues(alpha:0.1), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(challenge.emoji, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title,
                          style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(challenge.coachName,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(challenge.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            if (challenge.isJoined && challenge.status == ChallengeStatus.active) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Progress', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    '${challenge.myProgress.toInt()} / ${challenge.targetValue} ${challenge.unit}',
                    style: const TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: challenge.progressPercent,
                  backgroundColor: AppColors.surfaceDarkElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Icon(Icons.people_outline, color: AppColors.textTertiary, size: 14),
                const SizedBox(width: 4),
                Text('${challenge.participantCount} participants',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(width: 16),
                if (challenge.status == ChallengeStatus.active) ...[
                  const Icon(Icons.schedule, color: AppColors.textTertiary, size: 14),
                  const SizedBox(width: 4),
                  Text('${challenge.daysLeft} days left',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
                const Spacer(),
                if (!challenge.isJoined && challenge.status != ChallengeStatus.completed)
                  GestureDetector(
                    onTap: () async {
                      final ok = await ref.read(challengeNotifierProvider.notifier)
                          .joinChallenge(challenge.id);
                      if (ok) {
                        AppAnimations.hapticSuccess();
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to join — please try again.')));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Join', style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (challenge.isJoined)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, color: AppColors.success, size: 14),
                        SizedBox(width: 4),
                        Text('Joined', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
