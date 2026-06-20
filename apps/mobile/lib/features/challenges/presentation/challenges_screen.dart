import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../domain/challenge_provider.dart';
import '../data/models/challenge_model.dart';
import '../../../shared/theme/app_background.dart';
import 'widgets/challenge_card.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeChallengesProvider);
    final upcoming = ref.watch(upcomingChallengesProvider);
    final completed = ref.watch(completedChallengesProvider);
    final joined = ref.watch(challengeNotifierProvider).where((c) => c.isJoined && c.status == ChallengeStatus.active).toList();

    return AppGradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Challenges', style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold))
                        .fadeSlideIn(),
                    const SizedBox(height: 4),
                    Text('${joined.length} active challenges', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))
                        .fadeSlideIn(delay: 100.ms),
                    const SizedBox(height: 24),
                    if (joined.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.purple, AppColors.purpleDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('🏆', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text('My Active Challenges', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...joined.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${c.emoji} ${c.title}',
                                          style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text('${(c.progressPercent * 100).toInt()}%',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: c.progressPercent,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ).fadeSlideIn(delay: 200.ms),
                      const SizedBox(height: 24),
                    ],
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.purple,
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.textTertiary,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        Tab(text: 'Active (${active.length})'),
                        Tab(text: 'Upcoming (${upcoming.length})'),
                        Tab(text: 'Completed (${completed.length})'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildList(active),
              _buildList(upcoming),
              _buildList(completed),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildList(List<Challenge> challenges) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('No challenges here', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: challenges.length,
      itemBuilder: (context, index) => ChallengeCard(challenge: challenges[index], index: index),
    );
  }
}
