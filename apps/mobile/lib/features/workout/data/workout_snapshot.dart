import 'models/exercise_model.dart';
import 'models/workout_model.dart';

/// Conversion between a [Workout] and the plain-map shape used by
/// `program_workouts` rows and by `workout_sessions.workout_snapshot`.
///
/// One codec serves both so a session snapshot and a coach-authored program
/// workout deserialize through exactly the same path. [workoutToSnapshot] is
/// lossless: it writes a `set_details` list alongside the legacy
/// `sets`/`reps`/`weight` keys, so a workout with per-set variation survives a
/// round trip while a `program_workouts` row (which has no `set_details`) keeps
/// deserializing exactly as it did before.

/// Rebuilds a [Workout] from a `program_workouts` row or a session snapshot.
Workout programWorkoutToWorkout(Map<String, dynamic> w) {
  final exerciseList = List<Map<String, dynamic>>.from(w['exercises'] as List? ?? []);

  final exercises = exerciseList.asMap().entries.map((entry) {
    final i = entry.key;
    final e = entry.value;
    final setCount = (e['sets'] as int?) ?? 3;
    final reps = (e['reps'] as int?) ?? 10;
    final weight = ((e['weight'] as num?) ?? 0).toDouble();
    final rest = (e['rest_seconds'] as int?) ?? 90;
    final tempo = e['tempo'] as String?;

    // Prefer per-set detail when the source carries it (session snapshots);
    // fall back to the uniform sets/reps/weight shape (program_workouts rows).
    final details = e['set_details'] as List?;
    final sets = details != null
        ? details.asMap().entries.map((d) {
            final s = Map<String, dynamic>.from(d.value as Map);
            return WorkoutSet(
              setNumber: (s['set_number'] as int?) ?? d.key + 1,
              reps: (s['reps'] as int?) ?? reps,
              weight: ((s['weight'] as num?) ?? weight).toDouble(),
              restSeconds: (s['rest_seconds'] as int?) ?? rest,
              rpe: (s['rpe'] as num?)?.toDouble(),
              tempo: s['tempo'] as String? ?? tempo,
              notes: s['notes'] as String?,
            );
          }).toList()
        : List.generate(
            setCount,
            (si) => WorkoutSet(
              setNumber: si + 1,
              reps: reps,
              weight: weight,
              restSeconds: rest,
              tempo: tempo,
            ),
          );

    return WorkoutExercise(
      exercise: Exercise(
        id: (e['exercise_id'] as String?) ?? (e['id'] as String?) ?? 'ex_$i',
        name: (e['name'] as String?) ?? 'Exercise ${i + 1}',
        category: (e['category'] as String?) ?? 'Strength',
        muscleGroup: (e['muscle_group'] as String?) ?? '',
        equipment: (e['equipment'] as String?) ?? '',
        difficulty: (e['difficulty'] as String?) ?? 'Intermediate',
        description: (e['description'] as String?) ?? '',
        instructions: List<String>.from(e['instructions'] as List? ?? []),
      ),
      sets: sets,
      isSuperset: e['is_superset'] == true,
      supersetGroup: e['superset_group'] as String?,
      isCircuit: e['is_circuit'] == true,
      circuitGroup: e['circuit_group'] as String?,
      circuitRounds: (e['circuit_rounds'] as int?) ?? 1,
      notes: e['notes'] as String?,
    );
  }).toList();

  return Workout(
    id: (w['id'] as String?) ?? '',
    title: (w['title'] as String?) ?? 'Workout',
    description: (w['description'] as String?) ?? '',
    estimatedDuration: (w['estimated_minutes'] as int?) ?? 45,
    difficulty: (w['difficulty'] as String?) ?? 'Intermediate',
    category: (w['category'] as String?) ?? 'Strength',
    exercises: exercises,
    coachId: w['coach_id'] as String?,
    coachName: (w['coach_name'] as String?) ?? 'Your Coach',
  );
}

/// Serializes a [Workout] for `workout_sessions.workout_snapshot`.
Map<String, dynamic> workoutToSnapshot(Workout workout) => {
      'id': workout.id,
      'title': workout.title,
      'description': workout.description,
      'estimated_minutes': workout.estimatedDuration,
      'difficulty': workout.difficulty,
      'category': workout.category,
      if (workout.coachId != null) 'coach_id': workout.coachId,
      if (workout.coachName != null) 'coach_name': workout.coachName,
      'exercises': [
        for (final we in workout.exercises)
          {
            'exercise_id': we.exercise.id,
            'name': we.exercise.name,
            'category': we.exercise.category,
            'muscle_group': we.exercise.muscleGroup,
            'equipment': we.exercise.equipment,
            'difficulty': we.exercise.difficulty,
            'description': we.exercise.description,
            'instructions': we.exercise.instructions,
            // Legacy uniform shape, kept so anything reading a snapshot the old
            // way still sees a sensible set count.
            'sets': we.sets.length,
            'reps': we.sets.isEmpty ? 0 : we.sets.first.reps,
            'weight': we.sets.isEmpty ? 0 : we.sets.first.weight,
            'rest_seconds': we.sets.isEmpty ? 90 : (we.sets.first.restSeconds ?? 90),
            'tempo': we.sets.isEmpty ? null : we.sets.first.tempo,
            // Lossless per-set detail.
            'set_details': [
              for (final s in we.sets)
                {
                  'set_number': s.setNumber,
                  'reps': s.reps,
                  'weight': s.weight,
                  'rest_seconds': s.restSeconds,
                  'rpe': s.rpe,
                  'tempo': s.tempo,
                  'notes': s.notes,
                },
            ],
            'is_superset': we.isSuperset,
            'superset_group': we.supersetGroup,
            'is_circuit': we.isCircuit,
            'circuit_group': we.circuitGroup,
            'circuit_rounds': we.circuitRounds,
            'notes': we.notes,
          },
      ],
    };
