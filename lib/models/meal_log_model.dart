import 'food_model.dart'; 

class MealLogModel {
  final String id;
  final double quantity;
  final String mealType;
  final DateTime loggedAt;
  final double? totalCalories;
  final FoodModel? food; 

  MealLogModel({
    required this.id,
    required this.quantity,
    required this.mealType,
    required this.loggedAt,
    this.totalCalories,
    this.food,
  });

  factory MealLogModel.fromJson(Map<String, dynamic> json) {
    return MealLogModel(
      id: json['id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      mealType: json['mealType'] as String,
      loggedAt: DateTime.parse(json['loggedAt']),
      totalCalories: (json['totalCalories'] as num?)?.toDouble(),
      // Parse thông tin món ăn nếu có
      food: json['food'] != null ? FoodModel.fromJson(json['food']) : null,
    );
  }
}