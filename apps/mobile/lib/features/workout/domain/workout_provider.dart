import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../coach/data/coach_program_service.dart';
import '../../../core/realtime/realtime.dart';
import '../data/workout_service.dart';
import '../data/workout_session_store.dart';
import '../data/workout_snapshot.dart';
import 'workout_session_manager.dart';
import '../data/models/exercise_model.dart';
import '../data/models/workout_model.dart';
import '../../ai_coach/data/ai_coach_service.dart';

/// Today's coaching adjustment from the AI coach's daily insight — drives an
/// intensity/focus banner on the workout screen. null when there's no brief yet.
final coachAdjustmentProvider = FutureProvider.autoDispose<CoachAdjustment?>((ref) async {
  final insight = await AICoachService().getTodayInsight();
  if (insight == null) return null;
  final data = (insight['data'] as Map?) ?? const {};
  return CoachAdjustment(
    title: insight['title']?.toString() ?? 'Today’s Coaching',
    body: insight['body']?.toString() ?? '',
    focus: data['focus']?.toString(),
    intensityDelta: (data['intensity_delta'] as num?)?.round() ?? 0,
  );
});

class CoachAdjustment {
  final String title;
  final String body;
  final String? focus;
  final int intensityDelta; // % vs planned (-30..+10)
  const CoachAdjustment({required this.title, required this.body, this.focus, required this.intensityDelta});
}

/// Per-workout session status keyed by workout_title: the most recent session's
/// {status: in_progress|completed, started_at, completed_at, logged_sets}. Lets
/// the program list show "In Progress · started [date] · N%" instead of "Start".
final programSessionStatusProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  ref.watch(tableTickerProvider('workout_sessions'));
  ref.watch(tableTickerProvider('workout_set_logs'));
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser?.id;
  if (uid == null) return {};
  try {
    final sessions = await db
        .from('workout_sessions')
        .select('id, workout_title, status, started_at, completed_at')
        .eq('user_id', uid)
        .inFilter('status', ['in_progress', 'completed'])
        .order('started_at', ascending: false);
    final byTitle = <String, Map<String, dynamic>>{};
    for (final s in (sessions as List)) {
      final title = s['workout_title'] as String?;
      if (title == null) continue;
      byTitle.putIfAbsent(title, () => Map<String, dynamic>.from(s));
    }
    for (final e in byTitle.entries) {
      if (e.value['status'] == 'in_progress') {
        final logs = await db
            .from('workout_set_logs')
            .select('id')
            .eq('session_id', e.value['id']);
        e.value['logged_sets'] = (logs as List).length;
      }
    }
    return byTitle;
  } catch (_) {
    return {};
  }
});

final workoutServiceProvider = Provider<WorkoutService>((ref) => WorkoutService());

final workoutsProvider = Provider<List<Workout>>((ref) {
  return ref.watch(workoutServiceProvider).getSampleWorkouts();
});

final exercisesProvider = Provider<List<Exercise>>((ref) {
  return ref.watch(workoutServiceProvider).getSampleExercises();
});

final selectedWorkoutProvider = StateProvider<Workout?>((ref) => null);

/// Active rest countdown as a wall-clock end time + its original duration (for
/// the progress ring). App-scoped so it survives navigating away and resumes at
/// the correct remaining time. Null = no rest running.
class RestTimerState {
  final DateTime end;
  final int total;
  const RestTimerState(this.end, this.total);
}

final restTimerProvider = StateProvider<RestTimerState?>((ref) => null);

final exerciseSearchProvider = StateProvider<String>((ref) => '');

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final exercises = ref.watch(exercisesProvider);
  final search = ref.watch(exerciseSearchProvider).toLowerCase();
  if (search.isEmpty) return exercises;
  return exercises.where((e) =>
    e.name.toLowerCase().contains(search) ||
    e.muscleGroup.toLowerCase().contains(search) ||
    e.category.toLowerCase().contains(search)
  ).toList();
});

// ── Assigned program workouts from Supabase ───────────────────────────────────
final assignedWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  try {
    final program = await CoachProgramService().getMyAssignedProgram();
    if (program == null) return [];
    final workoutMaps = List<Map<String, dynamic>>.from(
        program['workouts'] as List? ?? []);
    return workoutMaps.map(programWorkoutToWorkout).toList();
  } catch (_) {
    return [];
  }
});

/// Generate a one-off, library-grounded AI workout for today (personalized to
/// goal/equipment/injuries/recovery + the coach's focus & intensity) and return
/// it as a startable Workout. null on failure.
Future<Workout?> generateAiWorkout({int? minutes}) async {
  try {
    final res = await Supabase.instance.client.functions.invoke(
      'ai-generate-workout',
      body: {if (minutes != null) 'duration_minutes': minutes});
    if (res.status != 200) return null;
    final w = (res.data as Map)['workout'];
    if (w is! Map) return null;
    return programWorkoutToWorkout(Map<String, dynamic>.from(w));
  } catch (_) { return null; }
}

// ── Workout session history ───────────────────────────────────────────────────
final workoutHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(workoutServiceProvider).getWorkoutHistory();
});

// ── Active workout in-memory state ────────────────────────────────────────────
class ActiveWorkoutNotifier extends StateNotifier<Map<String, List<Map<String, dynamic>>>> {
  ActiveWorkoutNotifier() : super({});

  /// Session these sets belong to. Entered sets are meaningless without it —
  /// keeping them together is what stops one workout's sets showing up under
  /// another.
  String? _sessionId;
  String? get sessionId => _sessionId;

  /// Binds this state to [sessionId], clearing it when the session changes.
  ///
  /// Called on entering the Workout Zone. Re-entering the same session keeps
  /// whatever was already typed; switching to a different session starts empty
  /// rather than inheriting the previous workout's sets.
  void beginSession(String sessionId) {
    if (_sessionId == sessionId) return;
    _sessionId = sessionId;
    state = {};
  }

  void updateSet(String exerciseId, int setIndex, String field, dynamic value) {
    final current = Map<String, List<Map<String, dynamic>>>.from(state);
    if (!current.containsKey(exerciseId)) current[exerciseId] = [];
    while (current[exerciseId]!.length <= setIndex) {
      current[exerciseId]!.add({});
    }
    current[exerciseId]![setIndex] = Map<String, dynamic>.from(current[exerciseId]![setIndex])..[field] = value;
    state = current;
  }

  /// Merge entered values (reps/weight/rpe/notes) into a set's in-memory state
  /// so the UI reflects them across rebuilds even if a row's State is recreated.
  void setSetData(String exerciseId, int setIndex, Map<String, dynamic> data) {
    final current = Map<String, List<Map<String, dynamic>>>.from(state);
    if (!current.containsKey(exerciseId)) current[exerciseId] = [];
    while (current[exerciseId]!.length <= setIndex) {
      current[exerciseId]!.add({});
    }
    current[exerciseId]![setIndex] = {
      ...current[exerciseId]![setIndex],
      ...data,
    };
    state = current;
  }

  void toggleSetComplete(String exerciseId, int setIndex) {
    final current = Map<String, List<Map<String, dynamic>>>.from(state);
    if (!current.containsKey(exerciseId)) current[exerciseId] = [];
    while (current[exerciseId]!.length <= setIndex) {
      current[exerciseId]!.add({'completed': false});
    }
    final set = Map<String, dynamic>.from(current[exerciseId]![setIndex]);
    set['completed'] = !(set['completed'] ?? false);
    current[exerciseId]![setIndex] = set;
    state = current;
  }

  /// Pre-populate from saved set logs when resuming a session.
  void restoreFromLogs(Map<String, List<Map<String, dynamic>>> logs) {
    final current = Map<String, List<Map<String, dynamic>>>.from(state);
    for (final entry in logs.entries) {
      current[entry.key] = entry.value;
    }
    state = current;
  }

  void reset() {
    _sessionId = null;
    state = {};
  }
}

final activeWorkoutProvider = StateNotifierProvider<ActiveWorkoutNotifier, Map<String, List<Map<String, dynamic>>>>(
  (ref) => ActiveWorkoutNotifier(),
);

// ── Stat providers ────────────────────────────────────────────────────────────
final weeklyWorkoutCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(workoutServiceProvider).getWeeklyWorkoutCount();
});

final currentStreakProvider = FutureProvider<int>((ref) async {
  return ref.watch(workoutServiceProvider).getCurrentStreak();
});

final totalWorkoutCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(workoutServiceProvider).getTotalWorkoutCount();
});

/// The one active workout session, or null.
///
/// The single source of truth for "is there a workout to resume". It watches
/// the `workout_sessions` ticker so starting, abandoning or completing a
/// session refreshes every surface that shows a Resume card — previously this
/// cached its first result for the lifetime of the app, which is why the same
/// build could show different workouts at different moments.
final activeSessionProvider = FutureProvider<WorkoutSessionRecord?>((ref) async {
  ref.watch(tableTickerProvider('workout_sessions'));
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;
  try {
    return await ref.watch(workoutSessionManagerProvider).activeSession(uid);
  } catch (_) {
    return null;
  }
});

final workoutSessionStoreProvider = Provider<WorkoutSessionStore>(
  (ref) => SupabaseWorkoutSessionStore(),
);

final workoutSessionManagerProvider = Provider<WorkoutSessionManager>(
  (ref) => WorkoutSessionManager(ref.watch(workoutSessionStoreProvider)),
);

/// Rebuilds the workout an active session belongs to and makes it the selected
/// workout, so every "Resume" entry point lands in the Workout Zone bound to
/// the session's own workout instead of whatever was last left in memory.
Future<Workout?> bindSessionToSelectedWorkout(
  WidgetRef ref,
  WorkoutSessionRecord session,
) async {
  final manager = ref.read(workoutSessionManagerProvider);
  final assigned = await ref.read(assignedWorkoutsProvider.future);
  final workout = manager.workoutForSession(
    session,
    candidates: [...assigned, ...ref.read(workoutsProvider)],
  );
  if (workout != null) {
    ref.read(selectedWorkoutProvider.notifier).state = workout;
  }
  return workout;
}

final personalRecordsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(workoutServiceProvider).getPersonalRecords();
});

final totalVolumeProvider = FutureProvider<double>((ref) async {
  return ref.watch(workoutServiceProvider).getTotalVolumeLifted();
});

final completionRateProvider = FutureProvider<double>((ref) async {
  return ref.watch(workoutServiceProvider).getCompletionRate();
});

final programAdherenceProvider = FutureProvider<double>((ref) async {
  return ref.watch(workoutServiceProvider).getProgramAdherence();
});

// ── Exercise progression (family: keyed by exercise name) ────────────────────
final exerciseProgressionProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, exerciseName) async {
  return ref.watch(workoutServiceProvider).getExerciseProgression(exerciseName);
});

final loggedExerciseNamesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(workoutServiceProvider).getLoggedExerciseNames();
});

// ── Coach: client workout stats ───────────────────────────────────────────────
final clientWorkoutStatsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, coachId) async => WorkoutService().getClientWorkoutStats(coachId),
);

final clientPersonalRecordsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, clientId) async => WorkoutService().getClientPersonalRecords(clientId),
);

final clientRecentSessionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, clientId) async => WorkoutService().getClientRecentSessions(clientId),
);
