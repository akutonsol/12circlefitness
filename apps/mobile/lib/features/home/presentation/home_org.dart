import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../workout/presentation/workout_list_screen.dart';
import '../../nutrition/presentation/nutrition_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../messaging/domain/messaging_provider.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final totalUnread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    final screens = [
      const DashboardScreen(),
      const WorkoutListScreen(),
      const NutritionScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      floatingActionButton: currentIndex == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    FloatingActionButton(
                      heroTag: 'messages',
                      onPressed: () => context.push('/messages'),
                      backgroundColor: AppColors.surfaceDark,
                      child: const Icon(Icons.chat_bubble_outline, color: AppColors.white),
                    ),
                    if (totalUnread > 0)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                          child: Center(
                            child: Text('$totalUnread',
                                style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'checkins',
                  onPressed: () => context.push('/checkins'),
                  backgroundColor: AppColors.warning,
                  child: const Icon(Icons.assignment_outlined, color: AppColors.white),
                ),
              ],
            )
          : currentIndex == 2
              ? FloatingActionButton(
                  heroTag: 'ai',
                  onPressed: () => context.push('/ai-nutrition'),
                  backgroundColor: AppColors.purple,
                  child: const Icon(Icons.psychology, color: AppColors.white),
                )
              : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgDarkSecondary,
          border: Border(top: BorderSide(color: AppColors.surfaceDarkElevated)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => ref.read(bottomNavIndexProvider.notifier).state = index,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.purple,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Workouts'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: 'Nutrition'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
