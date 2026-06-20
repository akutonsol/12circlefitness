enum HabitCategory { health, fitness, nutrition, mindfulness, sleep }

extension HabitCategoryExtension on HabitCategory {
  String get label {
    switch (this) {
      case HabitCategory.health: return 'Health';
      case HabitCategory.fitness: return 'Fitness';
      case HabitCategory.nutrition: return 'Nutrition';
      case HabitCategory.mindfulness: return 'Mindfulness';
      case HabitCategory.sleep: return 'Sleep';
    }
  }
}

class Habit {
  final String id;
  final String name;
  final String emoji;
  final HabitCategory category;
  final int targetValue;
  final String unit;
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> completedDates;
  final bool isCompletedToday;
  final int currentValue;
  final String? reminderTime;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.targetValue,
    required this.unit,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedDates,
    required this.isCompletedToday,
    required this.currentValue,
    this.reminderTime,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  Habit copyWith({
    int? currentValue,
    bool? isCompletedToday,
    int? currentStreak,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id,
      name: name,
      emoji: emoji,
      category: category,
      targetValue: targetValue,
      unit: unit,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak,
      completedDates: completedDates ?? this.completedDates,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      currentValue: currentValue ?? this.currentValue,
      reminderTime: reminderTime,
    );
  }
}
