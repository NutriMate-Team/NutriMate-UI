class CreateMealLogDto {
  final String foodId;
  final double quantity;
  final String mealType;

  CreateMealLogDto({
    required this.foodId,
    required this.quantity,
    required this.mealType,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'quantity': quantity,
      'mealType': mealType,
    };
  }
}