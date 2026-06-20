import 'models/habit_model.dart';

class HabitService {
  List<Habit> getDefaultHabits() {
    return [
      Habit(id: '1', name: 'Water Intake', emoji: '💧', category: HabitCategory.health, targetValue: 8, unit: 'glasses', currentStreak: 7, longestStreak: 14, completedDates: [], isCompletedToday: false, currentValue: 5, reminderTime: '09:00'),
      Habit(id: '2', name: 'Sleep', emoji: '😴', category: HabitCategory.sleep, targetValue: 8, unit: 'hours', currentStreak: 4, longestStreak: 10, completedDates: [], isCompletedToday: false, currentValue: 7, reminderTime: '22:00'),
      Habit(id: '3', name: 'Steps', emoji: '👟', category: HabitCategory.fitness, targetValue: 10000, unit: 'steps', currentStreak: 12, longestStreak: 21, completedDates: [], isCompletedToday: false, currentValue: 6240, reminderTime: null),
      Habit(id: '4', name: 'Meditation', emoji: '🧘', category: HabitCategory.mindfulness, targetValue: 10, unit: 'minutes', currentStreak: 3, longestStreak: 7, completedDates: [], isCompletedToday: false, currentValue: 0, reminderTime: '07:00'),
      Habit(id: '5', name: 'Supplements', emoji: '💊', category: HabitCategory.nutrition, targetValue: 1, unit: 'serving', currentStreak: 9, longestStreak: 30, completedDates: [], isCompletedToday: true, currentValue: 1, reminderTime: '08:00'),
      Habit(id: '6', name: 'Workout', emoji: '🏋️', category: HabitCategory.fitness, targetValue: 1, unit: 'session', currentStreak: 5, longestStreak: 14, completedDates: [], isCompletedToday: false, currentValue: 0, reminderTime: '06:00'),
      Habit(id: '7', name: 'Protein Goal', emoji: '🥩', category: HabitCategory.nutrition, targetValue: 140, unit: 'grams', currentStreak: 6, longestStreak: 12, completedDates: [], isCompletedToday: false, currentValue: 85, reminderTime: null),
      Habit(id: '8', name: 'Screen Free Time', emoji: '📵', category: HabitCategory.mindfulness, targetValue: 60, unit: 'minutes', currentStreak: 2, longestStreak: 5, completedDates: [], isCompletedToday: false, currentValue: 0, reminderTime: '21:00'),
    ];
  }

  double calculateAdherenceScore(List<Habit> habits) {
    if (habits.isEmpty) return 0;
    final completed = habits.where((h) => h.isCompletedToday).length;
    return (completed / habits.length) * 100;
  }

  int calculateTotalStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0;
    return (habits.map((h) => h.currentStreak).reduce((a, b) => a + b) / habits.length).round();
  }
}
