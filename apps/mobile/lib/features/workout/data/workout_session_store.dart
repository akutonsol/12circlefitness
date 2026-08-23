import 'package:supabase_flutter/supabase_flutter.dart';

/// One row of `workout_sessions`, in the shape the resume logic needs.
class WorkoutSessionRecord {
  final String id;
  final String userId;

  /// Id of the [Workout] this session was started from. May be empty for rows
  /// written before workout identity was persisted (migration 103).
  final String workoutId;
  final String workoutTitle;

  /// `in_progress` | `completed` | `abandoned`.
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int elapsedSeconds;

  /// Full workout definition as selected, so a resume can rebuild it without
  /// looking the workout up by title. Null for pre-migration rows.
  final Map<String, dynamic>? workoutSnapshot;

  const WorkoutSessionRecord({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutTitle,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.elapsedSeconds = 0,
    this.workoutSnapshot,
  });

  bool get isInProgress => status == WorkoutSessionStatus.inProgress;

  factory WorkoutSessionRecord.fromMap(Map<String, dynamic> row) =>
      WorkoutSessionRecord(
        id: row['id']?.toString() ?? '',
        userId: row['user_id']?.toString() ?? '',
        workoutId: row['workout_id']?.toString() ?? '',
        workoutTitle: row['workout_title']?.toString() ?? '',
        status: row['status']?.toString() ?? WorkoutSessionStatus.inProgress,
        startedAt: DateTime.tryParse(row['started_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        completedAt: DateTime.tryParse(row['completed_at']?.toString() ?? ''),
        elapsedSeconds: (row['elapsed_seconds'] as num?)?.toInt() ?? 0,
        workoutSnapshot: row['workout_snapshot'] is Map
            ? Map<String, dynamic>.from(row['workout_snapshot'] as Map)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'workout_id': workoutId,
        'workout_title': workoutTitle,
        'status': status,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'elapsed_seconds': elapsedSeconds,
        'workout_snapshot': workoutSnapshot,
      };
}

abstract final class WorkoutSessionStatus {
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const abandoned = 'abandoned';
}

/// Persistence operations the session rules need.
///
/// This is a seam over the existing `workout_sessions` table, not a second
/// persistence mechanism — [SupabaseWorkoutSessionStore] is the only
/// implementation the app runs. It exists so the rules in
/// `WorkoutSessionManager` can be exercised deterministically in tests.
abstract class WorkoutSessionStore {
  /// Every `in_progress` session for [userId], newest first.
  Future<List<WorkoutSessionRecord>> inProgressSessions(String userId);

  Future<WorkoutSessionRecord> createSession({
    required String userId,
    required String workoutId,
    required String workoutTitle,
    required Map<String, dynamic> workoutSnapshot,
  });

  /// Marks [sessionIds] `abandoned`. Rows and their set logs are preserved.
  Future<void> abandonSessions(Iterable<String> sessionIds);

  Future<void> completeSession({
    required String sessionId,
    required int durationSeconds,
    required int idleSeconds,
    required int caloriesBurned,
  });

  Future<void> saveElapsed(String sessionId, int elapsedSeconds);
}

/// Production store, backed by the existing Supabase `workout_sessions` table.
class SupabaseWorkoutSessionStore implements WorkoutSessionStore {
  final SupabaseClient _db;
  SupabaseWorkoutSessionStore([SupabaseClient? db])
      : _db = db ?? Supabase.instance.client;

  @override
  Future<List<WorkoutSessionRecord>> inProgressSessions(String userId) async {
    final rows = await _db
        .from('workout_sessions')
        .select()
        .eq('user_id', userId)
        .eq('status', WorkoutSessionStatus.inProgress)
        .order('started_at', ascending: false);
    return [
      for (final row in (rows as List))
        WorkoutSessionRecord.fromMap(Map<String, dynamic>.from(row as Map)),
    ];
  }

  @override
  Future<WorkoutSessionRecord> createSession({
    required String userId,
    required String workoutId,
    required String workoutTitle,
    required Map<String, dynamic> workoutSnapshot,
  }) async {
    final row = await _db
        .from('workout_sessions')
        .insert({
          'user_id': userId,
          'workout_id': workoutId,
          'workout_title': workoutTitle,
          'workout_snapshot': workoutSnapshot,
          'status': WorkoutSessionStatus.inProgress,
          'started_at': DateTime.now().toIso8601String(),
          'elapsed_seconds': 0,
        })
        .select()
        .single();
    return WorkoutSessionRecord.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> abandonSessions(Iterable<String> sessionIds) async {
    final ids = sessionIds.toList();
    if (ids.isEmpty) return;
    await _db
        .from('workout_sessions')
        .update({'status': WorkoutSessionStatus.abandoned})
        .inFilter('id', ids);
  }

  @override
  Future<void> completeSession({
    required String sessionId,
    required int durationSeconds,
    required int idleSeconds,
    required int caloriesBurned,
  }) async {
    await _db.from('workout_sessions').update({
      'status': WorkoutSessionStatus.completed,
      'completed_at': DateTime.now().toIso8601String(),
      'duration_seconds': durationSeconds,
      'idle_seconds': idleSeconds,
      'calories_burned': caloriesBurned,
    }).eq('id', sessionId);
  }

  @override
  Future<void> saveElapsed(String sessionId, int elapsedSeconds) async {
    await _db
        .from('workout_sessions')
        .update({'elapsed_seconds': elapsedSeconds})
        .eq('id', sessionId);
  }
}
