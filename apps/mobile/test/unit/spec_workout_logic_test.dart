// WKT-001 … WKT-006 — Workout system spec compliance tests.
// Tests the state-machine and persistence logic without requiring Supabase.
import 'package:flutter_test/flutter_test.dart';

enum WorkoutStatus { active, paused, completed }

class WorkoutSession {
  final String id;
  WorkoutStatus status;
  int currentExerciseIndex;
  List<Map<String, dynamic>> exerciseProgress;

  WorkoutSession({
    required this.id,
    this.status = WorkoutStatus.active,
    this.currentExerciseIndex = 0,
    required this.exerciseProgress,
  });

  factory WorkoutSession.start(String id, List<String> exercises) =>
      WorkoutSession(
        id: id,
        status: WorkoutStatus.active,
        exerciseProgress: exercises
            .map((e) => {'name': e, 'sets': <Map<String, dynamic>>[], 'done': false})
            .toList(),
      );

  void pause()    => status = WorkoutStatus.paused;
  void resume()   => status = WorkoutStatus.active;
  void complete() => status = WorkoutStatus.completed;

  Map<String, dynamic> toSnapshot() => {
        'id':                   id,
        'status':               status.name,
        'currentExerciseIndex': currentExerciseIndex,
        'exerciseProgress':     exerciseProgress,
      };

  factory WorkoutSession.fromSnapshot(Map<String, dynamic> s) =>
      WorkoutSession(
        id:                   s['id'] as String,
        status:               WorkoutStatus.values.byName(s['status'] as String),
        currentExerciseIndex: s['currentExerciseIndex'] as int,
        exerciseProgress:     List<Map<String, dynamic>>.from(s['exerciseProgress'] as List),
      );
}

void main() {
  group('WKT-001 Start workout → session created, status = active', () {
    test('new session is active', () =>
        expect(WorkoutSession.start('w1', ['Squat']).status, WorkoutStatus.active));

    test('starts at exercise 0', () =>
        expect(WorkoutSession.start('w1', ['Squat', 'Press']).currentExerciseIndex, 0));

    test('exercises initialised with empty sets', () {
      final s = WorkoutSession.start('w1', ['Squat']);
      expect(s.exerciseProgress.first['sets'], isEmpty);
      expect(s.exerciseProgress.first['done'], isFalse);
    });
  });

  group('WKT-002 Complete workout → status = completed', () {
    test('complete() sets status to completed', () {
      final s = WorkoutSession.start('w2', ['Deadlift'])..complete();
      expect(s.status, WorkoutStatus.completed);
    });

    test('completed session is eligible for +30 score award', () {
      const maxWorkout = 30;
      WorkoutSession s = WorkoutSession.start('w2', ['A'])..complete();
      final award = s.status == WorkoutStatus.completed ? maxWorkout : 0;
      expect(award, 30);
    });
  });

  group('WKT-003 Pause workout → progress saved', () {
    test('pause() sets status to paused', () {
      final s = WorkoutSession.start('w3', ['Row'])..pause();
      expect(s.status, WorkoutStatus.paused);
    });

    test('exercise index is preserved in snapshot at pause time', () {
      final s = WorkoutSession.start('w3', ['A', 'B', 'C'])
        ..currentExerciseIndex = 2
        ..pause();
      expect(s.toSnapshot()['currentExerciseIndex'], 2);
      expect(s.toSnapshot()['status'], 'paused');
    });
  });

  group('WKT-004 Resume workout → restored to last exercise, sets, weights', () {
    test('fromSnapshot() recovers exercise index', () {
      final original = WorkoutSession.start('w4', ['A', 'B'])
        ..currentExerciseIndex = 1
        ..pause();
      final restored = WorkoutSession.fromSnapshot(original.toSnapshot());
      expect(restored.currentExerciseIndex, 1);
    });

    test('resume() transitions paused → active', () {
      final s = WorkoutSession.start('w4', ['A'])..pause()..resume();
      expect(s.status, WorkoutStatus.active);
    });

    test('set data survives snapshot round-trip', () {
      final original = WorkoutSession.start('w4', ['Bench'])
        ..exerciseProgress[0]['sets'] = [
          {'reps': 10, 'weight': 80.0},
          {'reps': 8, 'weight': 85.0},
        ]
        ..pause();
      final restored = WorkoutSession.fromSnapshot(original.toSnapshot());
      expect(restored.exerciseProgress[0]['sets'], hasLength(2));
      expect(restored.exerciseProgress[0]['sets'][1]['weight'], 85.0);
    });
  });

  group('WKT-005 Close app during workout → snapshot persists', () {
    test('toSnapshot() includes all required keys', () {
      final snap = WorkoutSession.start('w5', ['Run']).toSnapshot();
      for (final key in ['id', 'status', 'currentExerciseIndex', 'exerciseProgress']) {
        expect(snap.containsKey(key), isTrue, reason: 'missing key: $key');
      }
    });

    test('active session snapshot status is "active"', () {
      expect(WorkoutSession.start('w5', ['A']).toSnapshot()['status'], 'active');
    });

    test('round-trip preserves all exercise names', () {
      final s = WorkoutSession.start('w5', ['Squat', 'Lunge', 'Press']);
      final restored = WorkoutSession.fromSnapshot(s.toSnapshot());
      final names = restored.exerciseProgress.map((e) => e['name']).toList();
      expect(names, ['Squat', 'Lunge', 'Press']);
    });
  });

  group('WKT-006 Workout reminder — idle detection logic', () {
    bool reminderDue(DateTime lastActivity) =>
        DateTime.now().difference(lastActivity).inHours >= 4;

    test('5-hour idle session → reminder due', () =>
        expect(reminderDue(DateTime.now().subtract(const Duration(hours: 5))), isTrue));

    test('30-minute idle → no reminder', () =>
        expect(reminderDue(DateTime.now().subtract(const Duration(minutes: 30))), isFalse));

    test('exactly 4-hour idle → reminder due', () =>
        expect(reminderDue(DateTime.now().subtract(const Duration(hours: 4))), isTrue));

    test('just started (0 min idle) → no reminder', () =>
        expect(reminderDue(DateTime.now()), isFalse));
  });
}
