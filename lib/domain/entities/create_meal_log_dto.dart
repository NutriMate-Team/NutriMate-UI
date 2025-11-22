class CreateMealLogDto {
  final String foodId;
  final double quantity;
  final String mealType;

  // --- THÊM CÁC TRƯỜNG OPTIONAL NÀY ---
  final String? source;
  final String? name;
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;

  CreateMealLogDto({
    required this.foodId,
    required this.quantity,
    required this.mealType,
    this.source,
    this.name,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
  });

  // Hàm chuyển đổi sang JSON để gửi Body API
  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'quantity': quantity,
      'mealType': mealType,
      // Chỉ gửi nếu có dữ liệu (để tránh gửi null)
      if (source != null) 'source': source,
      if (name != null) 'name': name,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (fat != null) 'fat': fat,
      if (carbs != null) 'carbs': carbs,
    };
  }
}