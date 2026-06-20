import 'exercise_model.dart';

class WorkoutSet {
  final int setNumber;
  final int reps;
  final double weight;
  final int? restSeconds;
  final double? rpe;
  final String? tempo;
  final String? notes;
  bool completed;

  WorkoutSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.restSeconds,
    this.rpe,
    this.tempo,
    this.notes,
    this.completed = false,
  });
}

class WorkoutExercise {
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final bool isSuperset;
  final String? supersetGroup;
  final bool isCircuit;
  final String? circuitGroup;
  final int circuitRounds;
  final String? notes;

  WorkoutExercise({
    required this.exercise,
    required this.sets,
    this.isSuperset = false,
    this.supersetGroup,
    this.isCircuit = false,
    this.circuitGroup,
    this.circuitRounds = 1,
    this.notes,
  });
}

class Workout {
  final String id;
  final String title;
  final String description;
  final int estimatedDuration;
  final String difficulty;
  final String category;
  final List<WorkoutExercise> exercises;
  final String? coachId;
  final String? coachName;
  final bool isCompleted;
  final DateTime? scheduledDate;

  Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedDuration,
    required this.difficulty,
    required this.category,
    required this.exercises,
    this.coachId,
    this.coachName,
    this.isCompleted = false,
    this.scheduledDate,
  });
}

class WorkoutProgram {
  final String id;
  final String title;
  final String description;
  final int durationWeeks;
  final int daysPerWeek;
  final String difficulty;
  final List<Workout> workouts;
  final String? coachId;
  final String? coachName;

  WorkoutProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.durationWeeks,
    required this.daysPerWeek,
    required this.difficulty,
    required this.workouts,
    this.coachId,
    this.coachName,
  });
}
