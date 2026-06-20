import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../domain/class_provider.dart';
import '../../../shared/theme/app_background.dart';
import '../../auth/domain/auth_provider.dart';
import 'create_class_screen.dart';
import 'widgets/class_card.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen>
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
    final live = ref.watch(liveNowClassesProvider);
    final upcoming = ref.watch(scheduleClassesProvider);
    final myBookings = ref.watch(myClassBookingsProvider).valueOrNull ?? [];
    final isCoach = ref.watch(currentUserProfileProvider).valueOrNull?['role'] == 'coach';

    return AppGradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isCoach
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.purple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              onPressed: () async {
                final created = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const CreateClassScreen()));
                if (created == true) {
                  ref.read(refreshClassesProvider.notifier).state++;
                }
              },
            )
          : null,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Classes', style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold))
                        .fadeSlideIn(),
                    const SizedBox(height: 4),
                    Text('${myBookings.length} bookings', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))
                        .fadeSlideIn(delay: 100.ms),
                    if (live.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${live.length} class${live.length > 1 ? 'es' : ''} happening now!',
                                  style: const TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: AppColors.error, size: 14),
                          ],
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                    ],
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.purple,
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.textTertiary,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        Tab(text: 'Schedule'),
                        Tab(text: 'My Bookings (${myBookings.length})'),
                        Tab(text: 'Live${live.isNotEmpty ? ' (${live.length})' : ''}'),
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
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: upcoming.length,
                itemBuilder: (context, index) => ClassCard(fitnessClass: upcoming[index], index: index),
              ),
              myBookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📅', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          const Text('No bookings yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Book a class to get started', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: myBookings.length,
                      itemBuilder: (context, index) => ClassCard(fitnessClass: myBookings[index], index: index),
                    ),
              live.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📺', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          const Text('No live classes right now', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: live.length,
                      itemBuilder: (context, index) => ClassCard(fitnessClass: live[index], index: index),
                    ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
