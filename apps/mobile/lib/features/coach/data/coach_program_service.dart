import 'package:supabase_flutter/supabase_flutter.dart';

class CoachProgramService {
  final _db = Supabase.instance.client;

  // ── Programs ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMyPrograms() async {
    final coachId = _db.auth.currentUser?.id;
    if (coachId == null) return [];
    final data = await _db
        .from('workout_programs')
        .select('*, program_workouts(count)')
        .eq('coach_id', coachId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createProgram(Map<String, dynamic> data) async {
    final coachId = _db.auth.currentUser?.id;
    return await _db.from('workout_programs').insert({
      ...data,
      'coach_id': coachId,
    }).select().single();
  }

  Future<void> addWorkoutToProgram(String programId, Map<String, dynamic> workout) async {
    await _db.from('program_workouts').insert({
      ...workout,
      'program_id': programId,
    });
  }

  Future<List<Map<String, dynamic>>> getProgramWorkouts(String programId) async {
    final data = await _db
        .from('program_workouts')
        .select()
        .eq('program_id', programId)
        .order('week_number')
        .order('sort_order');
    return List<Map<String, dynamic>>.from(data);
  }

  // ── Program Builder edits (Module 31) ────────────────────
  Future<void> updateProgram(String programId, Map<String, dynamic> data) async {
    await _db.from('workout_programs').update(data).eq('id', programId);
  }

  Future<void> deleteProgram(String programId) async {
    // program_workouts cascade-delete via the FK ON DELETE CASCADE.
    await _db.from('workout_programs').delete().eq('id', programId);
  }

  Future<void> updateWorkout(String workoutId, Map<String, dynamic> data) async {
    await _db.from('program_workouts').update(data).eq('id', workoutId);
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _db.from('program_workouts').delete().eq('id', workoutId);
  }

  // ── Assign program to client ─────────────────────────────
  Future<void> assignProgram(String programId, String clientId) async {
    final coachId = _db.auth.currentUser?.id;
    if (coachId == null) return;
    // Deactivate any existing assignment
    await _db.from('workout_program_assignments')
        .update({'status': 'replaced'})
        .eq('client_id', clientId)
        .eq('status', 'active');
    await _db.from('workout_program_assignments').insert({
      'program_id': programId,
      'client_id': clientId,
      'coach_id': coachId,
      'start_date': DateTime.now().toIso8601String().split('T')[0],
      'current_week': 1,
      'status': 'active',
    });
    await _db.from('notifications').insert({
      'recipient_id': clientId,
      'type': 'program_assigned',
      'title': 'New Workout Program',
      'body': 'Your coach has assigned you a new workout program. Check your training tab!',
      'read': false,
    });
  }

  // ── Client reads their assigned program ──────────────────
  Future<Map<String, dynamic>?> getMyAssignedProgram() async {
    final clientId = _db.auth.currentUser?.id;
    if (clientId == null) return null;
    final assignment = await _db
        .from('workout_program_assignments')
        .select('*, workout_programs(*)')
        .eq('client_id', clientId)
        .eq('status', 'active')
        .maybeSingle();
    if (assignment == null) return null;
    final programId = assignment['program_id'] as String;
    final workouts = await getProgramWorkouts(programId);
    return {...assignment, 'workouts': workouts};
  }

  // ── Today's workout for client ───────────────────────────
  Future<Map<String, dynamic>?> getTodaysWorkout() async {
    final program = await getMyAssignedProgram();
    if (program == null) return null;
    final workouts = program['workouts'] as List<Map<String, dynamic>>? ?? [];
    final currentWeek = program['current_week'] as int? ?? 1;
    final today = _dayName(DateTime.now().weekday);
    final todayWorkout = workouts.where((w) =>
      w['week_number'] == currentWeek && w['day_of_week'] == today
    ).firstOrNull;
    return todayWorkout;
  }

  String _dayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  // ── Assign nutrition plan ────────────────────────────────
  Future<void> assignNutritionPlan(String clientId, {
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    int? waterOz,
    String? notes,
  }) async {
    final coachId = _db.auth.currentUser?.id;
    if (coachId == null) return;
    await _db.from('client_nutrition_plans')
        .update({'is_active': false})
        .eq('client_id', clientId)
        .eq('is_active', true);
    await _db.from('client_nutrition_plans').insert({
      'client_id': clientId,
      'coach_id': coachId,
      'calories_target': calories,
      'protein_g': protein,
      'carbs_g': carbs,
      'fat_g': fat,
      'water_target_oz': waterOz,
      'notes': notes,
      'is_active': true,
    });
    await _db.from('notifications').insert({
      'recipient_id': clientId,
      'type': 'nutrition_assigned',
      'title': 'Nutrition Plan Updated',
      'body': 'Your coach has set your nutrition targets. Check your nutrition tab!',
      'read': false,
    });
  }

  /// Coach: the active nutrition plan for a specific client (to pre-fill the sheet).
  Future<Map<String, dynamic>?> getClientNutritionPlan(String clientId) async {
    return await _db
        .from('client_nutrition_plans')
        .select()
        .eq('client_id', clientId)
        .eq('is_active', true)
        .maybeSingle();
  }

  /// Coach: the active habits assigned to a specific client (to pre-fill the sheet).
  Future<List<Map<String, dynamic>>> getClientHabits(String clientId) async {
    final rows = await _db
        .from('client_habits')
        .select()
        .eq('client_id', clientId)
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> getMyNutritionPlan() async {
    final clientId = _db.auth.currentUser?.id;
    if (clientId == null) return null;
    return await _db
        .from('client_nutrition_plans')
        .select()
        .eq('client_id', clientId)
        .eq('is_active', true)
        .maybeSingle();
  }

  // ── Assign habits ────────────────────────────────────────
  Future<void> assignHabits(String clientId, List<Map<String, dynamic>> habits) async {
    final coachId = _db.auth.currentUser?.id;
    if (coachId == null) return;
    await _db.from('client_habits')
        .update({'is_active': false})
        .eq('client_id', clientId)
        .eq('is_active', true);
    final rows = habits.map((h) => {
      ...h,
      'client_id': clientId,
      'coach_id': coachId,
      'is_active': true,
    }).toList();
    await _db.from('client_habits').insert(rows);
    await _db.from('notifications').insert({
      'recipient_id': clientId,
      'type': 'habits_assigned',
      'title': 'Habits Assigned',
      'body': 'Your coach has set your daily habit targets. Start tracking today!',
      'read': false,
    });
  }

  Future<List<Map<String, dynamic>>> getMyHabits() async {
    final clientId = _db.auth.currentUser?.id;
    if (clientId == null) return [];
    final habits = await _db
        .from('client_habits')
        .select()
        .eq('client_id', clientId)
        .eq('is_active', true)
        .order('assigned_at');
    return List<Map<String, dynamic>>.from(habits);
  }

  // ── Log habit completion ─────────────────────────────────
  Future<void> logHabit(String habitId, {double value = 1, bool completed = true}) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _db.from('habit_logs').upsert({
      'habit_id': habitId,
      'user_id': userId,
      'logged_date': today,
      'value': value,
      'completed': completed,
      'logged_at': DateTime.now().toIso8601String(),
    }, onConflict: 'habit_id,logged_date');
  }

  Future<List<Map<String, dynamic>>> getTodayHabitLogs() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return [];
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await _db
        .from('habit_logs')
        .select()
        .eq('user_id', userId)
        .eq('logged_date', today);
    return List<Map<String, dynamic>>.from(data);
  }

  // Returns current streak per habit_id, calculated from the last 90 days of logs.
  Future<Map<String, int>> getHabitStreaks() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return {};
    final since = DateTime.now().subtract(const Duration(days: 90));
    final data = await _db
        .from('habit_logs')
        .select('habit_id, logged_date, completed')
        .eq('user_id', userId)
        .gte('logged_date', since.toIso8601String().split('T')[0])
        .order('logged_date', ascending: false);

    final logs = List<Map<String, dynamic>>.from(data);
    final completedDates = <String, Set<String>>{};
    for (final log in logs) {
      if (log['completed'] == true) {
        final id = log['habit_id'] as String;
        final date = log['logged_date'] as String;
        completedDates.putIfAbsent(id, () => {}).add(date);
      }
    }

    String fmt(DateTime d) => d.toIso8601String().split('T')[0];

    final result = <String, int>{};
    for (final entry in completedDates.entries) {
      int streak = 0;
      var check = DateTime.now();
      // If today not completed yet, start from yesterday
      if (!entry.value.contains(fmt(check))) {
        check = check.subtract(const Duration(days: 1));
      }
      while (entry.value.contains(fmt(check))) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      }
      result[entry.key] = streak;
    }
    return result;
  }

  Future<void> addCustomHabit({
    required String name,
    required String emoji,
    required String category,
    required int targetValue,
    required String unit,
  }) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    await _db.from('client_habits').insert({
      'client_id': userId,
      'name': name,
      'emoji': emoji,
      'category': category,
      'target_value': targetValue,
      'unit': unit,
      'is_active': true,
    });
  }

  /// Coach: has this client PAID for a plan with me? True if there's an active
  /// coach/package subscription or a paid one-time package payment between us.
  /// Coaches can only assign work once this is true.
  Future<bool> clientHasPaidPlan(String clientId) async {
    final coachId = _db.auth.currentUser?.id;
    if (coachId == null) return false;
    try {
      final sub = await _db
          .from('subscriptions')
          .select('id')
          .eq('user_id', clientId)
          .eq('coach_id', coachId)
          .inFilter('kind', ['coach', 'package_monthly'])
          .inFilter('status', ['active', 'trialing'])
          .limit(1)
          .maybeSingle();
      if (sub != null) return true;
      final pay = await _db
          .from('payments')
          .select('id')
          .eq('user_id', clientId)
          .eq('coach_id', coachId)
          .eq('kind', 'package')
          .eq('status', 'paid')
          .limit(1)
          .maybeSingle();
      return pay != null;
    } catch (_) {
      return false;
    }
  }
}
