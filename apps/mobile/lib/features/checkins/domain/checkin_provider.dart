import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/checkin_service.dart';
import '../data/weekly_checkin_service.dart';
import '../data/models/checkin_model.dart';

final checkinServiceProvider = Provider<CheckinService>((ref) => CheckinService());

final checkinStreakProvider = FutureProvider<int>((ref) async {
  return ref.watch(checkinServiceProvider).getCheckinStreak();
});

final recentCheckinsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(checkinServiceProvider).getRecentCheckins();
});

final hasCheckedInTodayProvider = FutureProvider<bool>((ref) async {
  return ref.watch(checkinServiceProvider).hasCheckedInToday();
});

final weeklyCheckinServiceProvider =
    Provider<WeeklyCheckinService>((ref) => WeeklyCheckinService());

final weeklyCheckinsProvider = FutureProvider<List<WeeklyCheckin>>((ref) async {
  return ref.watch(weeklyCheckinServiceProvider).getWeeklyCheckins();
});

final currentWeekCheckinProvider = FutureProvider<WeeklyCheckin>((ref) async {
  return ref.watch(weeklyCheckinServiceProvider).getCurrentWeekCheckin();
});

final selectedCheckinProvider = StateProvider<WeeklyCheckin?>((ref) => null);

final coachSubmittedCheckinsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(weeklyCheckinServiceProvider).getSubmittedCheckinsForCoach();
});

final selectedCoachCheckinProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);
