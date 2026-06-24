import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/exercise_model.dart';
import 'models/workout_model.dart';
import 'models/workout_log_model.dart';

class WorkoutService {
  final _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  // ── Sample data (fallback when no assigned program) ───────────────────────

  List<Exercise> getSampleExercises() => [
    Exercise(id: '1', name: 'Barbell Squat', category: 'Strength', muscleGroup: 'Legs', equipment: 'Barbell', difficulty: 'Intermediate', description: 'A compound lower body exercise.', instructions: ['Stand with feet shoulder-width apart', 'Lower your body until thighs are parallel', 'Drive through heels to stand']),
    Exercise(id: '2', name: 'Bench Press', category: 'Strength', muscleGroup: 'Chest', equipment: 'Barbell', difficulty: 'Intermediate', description: 'A compound upper body push exercise.', instructions: ['Lie on bench with feet flat', 'Grip bar slightly wider than shoulders', 'Lower bar to chest then press up']),
    Exercise(id: '3', name: 'Deadlift', category: 'Strength', muscleGroup: 'Back', equipment: 'Barbell', difficulty: 'Advanced', description: 'A fundamental compound pulling exercise.', instructions: ['Stand with feet hip-width apart', 'Hinge at hips and grip the bar', 'Drive hips forward to stand tall']),
    Exercise(id: '4', name: 'Pull Up', category: 'Strength', muscleGroup: 'Back', equipment: 'Bodyweight', difficulty: 'Intermediate', description: 'Upper body pulling movement.', instructions: ['Hang from bar with overhand grip', 'Pull chest to bar', 'Lower with control']),
    Exercise(id: '5', name: 'Dumbbell Lunges', category: 'Strength', muscleGroup: 'Legs', equipment: 'Dumbbells', difficulty: 'Beginner', description: 'Unilateral lower body exercise.', instructions: ['Hold dumbbells at sides', 'Step forward and lower back knee', 'Push back to start']),
    Exercise(id: '6', name: 'Plank', category: 'Core', muscleGroup: 'Core', equipment: 'Bodyweight', difficulty: 'Beginner', description: 'Isometric core stability exercise.', instructions: ['Start in push-up position', 'Hold body in straight line', 'Breathe steadily throughout']),
    Exercise(id: '7', name: 'Hip Thrust', category: 'Strength', muscleGroup: 'Glutes', equipment: 'Barbell', difficulty: 'Intermediate', description: 'Glute isolation exercise.', instructions: ['Sit against bench with bar over hips', 'Drive hips up to full extension', 'Squeeze glutes at top']),
    Exercise(id: '8', name: 'Romanian Deadlift', category: 'Strength', muscleGroup: 'Hamstrings', equipment: 'Barbell', difficulty: 'Intermediate', description: 'Hamstring focused hinge movement.', instructions: ['Stand with feet hip-width', 'Hinge forward keeping back flat', 'Feel stretch in hamstrings then return']),
  ];

  List<Workout> getSampleWorkouts() {
    final ex = getSampleExercises();
    return [
      Workout(id: '1', title: 'Full Body Strength', description: 'A complete full body workout targeting all major muscle groups.', estimatedDuration: 45, difficulty: 'Intermediate', category: 'Strength', coachName: 'Coach Sarah', exercises: [
        WorkoutExercise(exercise: ex[0], sets: [WorkoutSet(setNumber: 1, reps: 8, weight: 60, restSeconds: 90), WorkoutSet(setNumber: 2, reps: 8, weight: 60, restSeconds: 90), WorkoutSet(setNumber: 3, reps: 8, weight: 60, restSeconds: 90)]),
        WorkoutExercise(exercise: ex[1], sets: [WorkoutSet(setNumber: 1, reps: 10, weight: 50, restSeconds: 90), WorkoutSet(setNumber: 2, reps: 10, weight: 50, restSeconds: 90)]),
        WorkoutExercise(exercise: ex[5], sets: [WorkoutSet(setNumber: 1, reps: 30, weight: 0, restSeconds: 60), WorkoutSet(setNumber: 2, reps: 30, weight: 0, restSeconds: 60)]),
      ]),
      Workout(id: '2', title: 'Glute and Hamstring Focus', description: 'Target your posterior chain with this focused lower body session.', estimatedDuration: 50, difficulty: 'Intermediate', category: 'Strength', coachName: 'Coach Sarah', exercises: [
        WorkoutExercise(exercise: ex[6], sets: [WorkoutSet(setNumber: 1, reps: 12, weight: 80, restSeconds: 90), WorkoutSet(setNumber: 2, reps: 12, weight: 80, restSeconds: 90), WorkoutSet(setNumber: 3, reps: 12, weight: 80, restSeconds: 90)]),
        WorkoutExercise(exercise: ex[7], sets: [WorkoutSet(setNumber: 1, reps: 10, weight: 60, restSeconds: 90), WorkoutSet(setNumber: 2, reps: 10, weight: 60, restSeconds: 90)]),
      ]),
      // Example with superset
      Workout(id: '3', title: 'Upper Body + Core Circuit', description: 'Superset and circuit combo for upper body and core.', estimatedDuration: 40, difficulty: 'Advanced', category: 'Strength', coachName: 'Coach Sarah', exercises: [
        WorkoutExercise(exercise: ex[2], sets: [WorkoutSet(setNumber: 1, reps: 5, weight: 100, restSeconds: 120), WorkoutSet(setNumber: 2, reps: 5, weight: 100, restSeconds: 120)]),
        WorkoutExercise(exercise: ex[3], sets: [WorkoutSet(setNumber: 1, reps: 8, weight: 0, restSeconds: 60), WorkoutSet(setNumber: 2, reps: 8, weight: 0, restSeconds: 60)], isSuperset: true, supersetGroup: 'A'),
        WorkoutExercise(exercise: ex[1], sets: [WorkoutSet(setNumber: 1, reps: 10, weight: 40, restSeconds: 60), WorkoutSet(setNumber: 2, reps: 10, weight: 40, restSeconds: 60)], isSuperset: true, supersetGroup: 'A'),
        WorkoutExercise(exercise: ex[5], sets: [WorkoutSet(setNumber: 1, reps: 45, weight: 0, restSeconds: 30), WorkoutSet(setNumber: 2, reps: 45, weight: 0, restSeconds: 30), WorkoutSet(setNumber: 3, reps: 45, weight: 0, restSeconds: 30)], isCircuit: true, circuitGroup: 'C1', circuitRounds: 3),
        WorkoutExercise(exercise: ex[4], sets: [WorkoutSet(setNumber: 1, reps: 12, weight: 15, restSeconds: 30), WorkoutSet(setNumber: 2, reps: 12, weight: 15, restSeconds: 30), WorkoutSet(setNumber: 3, reps: 12, weight: 15, restSeconds: 30)], isCircuit: true, circuitGroup: 'C1', circuitRounds: 3),
      ]),
    ];
  }

  // ── Session management ────────────────────────────────────────────────────

  Future<void> logWorkout(WorkoutLog log) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _supabase.from('workout_logs').insert({
        'user_id': uid,
        'workout_title': log.workoutTitle,
        'duration_minutes': log.durationMinutes ?? 0,
        'calories_burned': log.caloriesBurned ?? 0,
        'category': log.category ?? 'Strength',
        'notes': log.notes ?? '',
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> saveSetLog({
    required String sessionId,
    required String exerciseName,
    required String exerciseId,
    required int setNumber,
    required int reps,
    required double weightKg,
    double? rpe,
    String? notes,
    String? tempo,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final cleanNotes = (notes != null && notes.isNotEmpty) ? notes : null;
    // Update-or-insert (one row per set) without relying on a DB unique
    // constraint, so editing a set's weight/reps/RPE/notes updates the same row
    // and re-completing it doesn't duplicate. rpe/notes/tempo are always written
    // (null when blank) so edits can clear them.
    try {
      final existing = await _supabase
          .from('workout_set_logs')
          .update({
            'exercise_id': exerciseId,
            'reps': reps,
            'weight_kg': weightKg,
            'rpe': rpe,
            'notes': cleanNotes,
            'tempo': tempo,
          })
          .eq('session_id', sessionId)
          .eq('exercise_name', exerciseName)
          .eq('set_number', setNumber)
          .select('id');
      if ((existing as List).isEmpty) {
        await _supabase.from('workout_set_logs').insert({
          'session_id': sessionId,
          'user_id': uid,
          'exercise_name': exerciseName,
          'exercise_id': exerciseId,
          'set_number': setNumber,
          'reps': reps,
          'weight_kg': weightKg,
          'rpe': rpe,
          'notes': cleanNotes,
          'tempo': tempo,
        });
      }
    } catch (_) {}
  }

  /// Returns {exerciseId: [{completed: true, reps, weight_kg, rpe, notes}]}
  Future<Map<String, List<Map<String, dynamic>>>> getSessionCompletedSets(String sessionId) async {
    try {
      final rows = await _supabase
          .from('workout_set_logs')
          .select()
          .eq('session_id', sessionId)
          .order('set_number');
      final result = <String, List<Map<String, dynamic>>>{};
      for (final row in (rows as List)) {
        final exId = row['exercise_id'] as String? ?? row['exercise_name'] as String? ?? '';
        result.putIfAbsent(exId, () => []).add({
          'completed': true,
          'reps': row['reps'],
          'weight': row['weight_kg'],
          'rpe': row['rpe'],
          'notes': row['notes'],
          'set_number': row['set_number'],
        });
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      return await _supabase
          .from('workout_sessions')
          .select()
          .eq('user_id', uid)
          .eq('status', 'in_progress')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (_) { return null; }
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWorkoutHistory({int limit = 20}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final data = await _supabase
          .from('workout_sessions')
          .select()
          .eq('user_id', uid)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getSessionSetLogs(String sessionId) async {
    try {
      final data = await _supabase
          .from('workout_set_logs')
          .select()
          .eq('session_id', sessionId)
          .order('exercise_name')
          .order('set_number');
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) { return []; }
  }

  // ── Progression data for a single exercise ────────────────────────────────

  /// Returns list of {date, max_weight, total_volume, sets_count} sorted by date asc.
  Future<List<Map<String, dynamic>>> getExerciseProgression(String exerciseName) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await _supabase
          .from('workout_set_logs')
          .select('weight_kg, reps, created_at')
          .eq('user_id', uid)
          .eq('exercise_name', exerciseName)
          .order('created_at');
      final grouped = <String, Map<String, dynamic>>{};
      for (final row in (rows as List)) {
        final date = (row['created_at'] as String).substring(0, 10);
        final weight = (row['weight_kg'] as num?)?.toDouble() ?? 0.0;
        final reps = (row['reps'] as int?) ?? 0;
        if (!grouped.containsKey(date)) {
          grouped[date] = {'date': date, 'max_weight': 0.0, 'total_volume': 0.0, 'sets_count': 0};
        }
        grouped[date]!['max_weight'] = (grouped[date]!['max_weight'] as double) < weight
            ? weight : grouped[date]!['max_weight'];
        grouped[date]!['total_volume'] = (grouped[date]!['total_volume'] as double) + weight * reps;
        grouped[date]!['sets_count'] = (grouped[date]!['sets_count'] as int) + 1;
      }
      return grouped.values.toList()..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    } catch (_) { return []; }
  }

  /// Returns all distinct exercise names this user has logged
  Future<List<String>> getLoggedExerciseNames() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await _supabase
          .from('workout_set_logs')
          .select('exercise_name')
          .eq('user_id', uid);
      final names = (rows as List).map((r) => r['exercise_name'] as String? ?? '').toSet().toList();
      names.sort();
      return names;
    } catch (_) { return []; }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<int> getWeeklyWorkoutCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final data = await _supabase
          .from('workout_logs')
          .select('id')
          .eq('user_id', uid)
          .gte('completed_at', start.toIso8601String());
      return (data as List).length;
    } catch (_) { return 0; }
  }

  Future<int> getCurrentStreak() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final data = await _supabase
          .from('workout_logs')
          .select('completed_at')
          .eq('user_id', uid)
          .order('completed_at', ascending: false)
          .limit(30);
      if ((data as List).isEmpty) return 0;
      int streak = 0;
      DateTime checkDate = DateTime.now();
      for (final log in data) {
        final logDate = DateTime.parse(log['completed_at']);
        final logDay = DateTime(logDate.year, logDate.month, logDate.day);
        final checkDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
        final diff = checkDay.difference(logDay).inDays;
        if (diff == 0 || diff == 1) {
          streak++;
          checkDate = logDay.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    } catch (_) { return 0; }
  }

  Future<int> getTotalWorkoutCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final data = await _supabase.from('workout_logs').select('id').eq('user_id', uid);
      return (data as List).length;
    } catch (_) { return 0; }
  }

  /// Completion rate over last 30 days: completed / (completed + abandoned)
  Future<double> getCompletionRate() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final rows = await _supabase
          .from('workout_sessions')
          .select('status')
          .eq('user_id', uid)
          .gte('started_at', cutoff)
          .inFilter('status', ['completed', 'abandoned']);
      final all = (rows as List);
      if (all.isEmpty) return 0;
      final completed = all.where((r) => r['status'] == 'completed').length;
      return completed / all.length;
    } catch (_) { return 0; }
  }

  /// Program adherence: workouts done this week / target days per week
  Future<double> getProgramAdherence({int targetDaysPerWeek = 4}) async {
    final count = await getWeeklyWorkoutCount();
    return (count / targetDaysPerWeek).clamp(0.0, 1.0);
  }

  Future<List<Map<String, dynamic>>> getPersonalRecords() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final data = await _supabase
          .from('workout_set_logs')
          .select('exercise_name, weight_kg, reps')
          .eq('user_id', uid)
          .gt('weight_kg', 0);
      final rows = List<Map<String, dynamic>>.from(data as List);
      final prs = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final name = row['exercise_name'] as String;
        final weight = (row['weight_kg'] as num).toDouble();
        if (!prs.containsKey(name) || weight > (prs[name]!['weight_kg'] as double)) {
          prs[name] = {'exercise_name': name, 'weight_kg': weight, 'reps': row['reps']};
        }
      }
      return prs.values.toList()
        ..sort((a, b) => (b['weight_kg'] as double).compareTo(a['weight_kg'] as double));
    } catch (_) { return []; }
  }

  Future<double> getTotalVolumeLifted() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final data = await _supabase
          .from('workout_set_logs')
          .select('weight_kg, reps')
          .eq('user_id', uid);
      double total = 0;
      for (final row in (data as List)) {
        total += ((row['weight_kg'] as num?)?.toDouble() ?? 0) * ((row['reps'] as int?) ?? 0);
      }
      return total;
    } catch (_) { return 0; }
  }

  // ── Coach: client stats ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getClientWorkoutStats(String coachId) async {
    try {
      final rows = await _supabase
          .from('coach_client_workout_stats')
          .select()
          .eq('coach_id', coachId);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getClientPersonalRecords(String clientId) async {
    try {
      final data = await _supabase
          .from('workout_set_logs')
          .select('exercise_name, weight_kg, reps')
          .eq('user_id', clientId)
          .gt('weight_kg', 0);
      final rows = List<Map<String, dynamic>>.from(data as List);
      final prs = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final name = row['exercise_name'] as String;
        final weight = (row['weight_kg'] as num).toDouble();
        if (!prs.containsKey(name) || weight > (prs[name]!['weight_kg'] as double)) {
          prs[name] = {'exercise_name': name, 'weight_kg': weight, 'reps': row['reps']};
        }
      }
      return prs.values.toList()
        ..sort((a, b) => (b['weight_kg'] as double).compareTo(a['weight_kg'] as double));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getClientRecentSessions(String clientId, {int limit = 10}) async {
    try {
      final data = await _supabase
          .from('workout_sessions')
          .select()
          .eq('user_id', clientId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) { return []; }
  }
}
