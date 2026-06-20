class Food {
  final String id;
  final String name;
  final String brand;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double servingSize;
  final String servingUnit;
  final String? barcode;

  Food({
    required this.id,
    required this.name,
    required this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.servingSize,
    required this.servingUnit,
    this.barcode,
  });

  Food copyWithQuantity(double quantity) {
    final ratio = quantity / servingSize;
    return Food(
      id: id,
      name: name,
      brand: brand,
      calories: calories * ratio,
      protein: protein * ratio,
      carbs: carbs * ratio,
      fat: fat * ratio,
      fiber: fiber * ratio,
      sugar: sugar * ratio,
      servingSize: quantity,
      servingUnit: servingUnit,
      barcode: barcode,
    );
  }
}
