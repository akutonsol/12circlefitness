import 'food_model.dart';

enum MealType { breakfast, lunch, dinner, snack, proteinShake }

extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.dinner: return 'Dinner';
      case MealType.snack: return 'Snack';
      case MealType.proteinShake: return 'Protein Shake';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast: return '🌅';
      case MealType.lunch: return '☀️';
      case MealType.dinner: return '🌙';
      case MealType.snack: return '🍎';
      case MealType.proteinShake: return '🥤';
    }
  }
}

class MealEntry {
  final String id;
  final Food food;
  final double quantity;
  final MealType mealType;
  final DateTime loggedAt;

  MealEntry({
    required this.id,
    required this.food,
    required this.quantity,
    required this.mealType,
    required this.loggedAt,
  });

  double get calories => food.calories * (quantity / food.servingSize);
  double get protein => food.protein * (quantity / food.servingSize);
  double get carbs => food.carbs * (quantity / food.servingSize);
  double get fat => food.fat * (quantity / food.servingSize);
}

class DailyNutritionLog {
  final DateTime date;
  final List<MealEntry> entries;
  final double calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;

  DailyNutritionLog({
    required this.date,
    required this.entries,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
  });

  double get totalCalories => entries.fold(0, (sum, e) => sum + e.calories);
  double get totalProtein => entries.fold(0, (sum, e) => sum + e.protein);
  double get totalCarbs => entries.fold(0, (sum, e) => sum + e.carbs);
  double get totalFat => entries.fold(0, (sum, e) => sum + e.fat);

  List<MealEntry> entriesForMeal(MealType type) =>
      entries.where((e) => e.mealType == type).toList();
}
