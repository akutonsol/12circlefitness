import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exercise_database_service.dart';
import '../data/models/exercise_detail_model.dart';

final exerciseDatabaseServiceProvider = Provider<ExerciseDatabaseService>(
  (ref) => ExerciseDatabaseService(),
);

final allExercisesProvider = Provider<List<ExerciseDetail>>((ref) {
  return ref.watch(exerciseDatabaseServiceProvider).getAllExercises();
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final selectedMuscleGroupProvider = StateProvider<String>((ref) => 'All');
final selectedEquipmentProvider = StateProvider<String>((ref) => 'All');
final exerciseDbSearchProvider = StateProvider<String>((ref) => '');
final selectedExerciseDetailProvider = StateProvider<ExerciseDetail?>((ref) => null);

final filteredExerciseDbProvider = Provider<List<ExerciseDetail>>((ref) {
  final service = ref.watch(exerciseDatabaseServiceProvider);
  final exercises = ref.watch(allExercisesProvider);
  final category = ref.watch(selectedCategoryProvider);
  final muscleGroup = ref.watch(selectedMuscleGroupProvider);
  final equipment = ref.watch(selectedEquipmentProvider);
  final search = ref.watch(exerciseDbSearchProvider);

  return service.filterExercises(
    exercises: exercises,
    category: category,
    muscleGroup: muscleGroup,
    equipment: equipment,
    search: search,
  );
});
