import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goal_service.dart';
import '../data/models/goal.dart';

final goalServiceProvider = Provider<GoalService>((ref) => GoalService());

final myGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  return ref.watch(goalServiceProvider).getMyGoals();
});
