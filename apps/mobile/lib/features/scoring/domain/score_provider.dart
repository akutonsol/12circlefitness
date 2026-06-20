import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/score_engine.dart';

final scoreEngineProvider = Provider<ScoreEngine>((ref) => ScoreEngine());

/// Bumped after an award so the dashboards refresh.
final scoreRefreshProvider = StateProvider<int>((ref) => 0);

final myScoreProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(scoreRefreshProvider);
  return ref.watch(scoreEngineProvider).myScore();
});

final recentScoreEventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(scoreRefreshProvider);
  return ref.watch(scoreEngineProvider).recentEvents();
});

final allBadgesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(scoreEngineProvider).allBadges();
});

final myBadgeIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(scoreRefreshProvider);
  return ref.watch(scoreEngineProvider).myBadgeIds();
});

final globalLeaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(scoreRefreshProvider);
  return ref.watch(scoreEngineProvider).leaderboardGlobal();
});

/// Coach group leaderboard for a given coach id.
final coachLeaderboardProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, coachId) async {
  ref.watch(scoreRefreshProvider);
  return ref.watch(scoreEngineProvider).leaderboardCoach(coachId);
});

/// A specific client's score (for coach analytics).
final clientScoreProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, clientId) async {
  ref.watch(scoreRefreshProvider);
  return ref.watch(scoreEngineProvider).clientScore(clientId);
});
