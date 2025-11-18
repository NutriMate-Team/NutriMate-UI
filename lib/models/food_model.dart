class FoodModel {
  final String id;
  final String name;
  final String source; // 'vietnam_nin', 'usda', 'openfoodfacts'
  final String unit; // '100g'

  // === Macronutrients (Đa lượng) ===
  final double? calories; // Kcal
  final double? protein;  // g
  final double? fat;      // g
  final double? carbs;    // g

  // === Chi tiết (Detail Macros) ===
  final double? fiber;        // Chất xơ (g)
  final double? sugar;        // Đường (g)
  final double? saturatedFat; // Chất béo bão hòa (g)
  final double? cholesterol;  // mg

  // === Khoáng chất (Minerals) ===
  final double? sodium;    // Natri (mg)
  final double? potassium; // Kali (mg)
  final double? calcium;   // Canxi (mg)
  final double? iron;      // Sắt (mg)
  final double? magnesium; // Magie (mg)

  // === Vitamins ===
  final double? vitaminA; // µg (microgram)
  final double? vitaminC; // mg
  final double? vitaminD; // µg (microgram)
  final double? vitaminE; // mg
  final double? vitaminK; // µg (microgram)
  final double? vitaminB6; // mg
  final double? vitaminB12; // µg (microgram)

  FoodModel({
    required this.id,
    required this.name,
    required this.source,
    required this.unit,
    // Macros
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
    // Details
    this.fiber,
    this.sugar,
    this.saturatedFat,
    this.cholesterol,
    // Minerals
    this.sodium,
    this.potassium,
    this.calcium,
    this.iron,
    this.magnesium,
    // Vitamins
    this.vitaminA,
    this.vitaminC,
    this.vitaminD,
    this.vitaminE,
    this.vitaminK,
    this.vitaminB6,
    this.vitaminB12,
  });

  // Hàm "đọc" JSON từ Backend NestJS (đã cập nhật)
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    // Hàm trợ giúp nhỏ để parse an toàn
    double? safeDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return FoodModel(
      // Các trường bắt buộc
      id: json['id'].toString(),
      name: json['name'] as String,
      source: json['source'] as String,
      unit: json['unit'] as String,

      // === Macronutrients ===
      calories: safeDouble(json['calories']),
      protein: safeDouble(json['protein']),
      fat: safeDouble(json['fat']),
      carbs: safeDouble(json['carbs']),

      // === Chi tiết (Detail Macros) ===
      fiber: safeDouble(json['fiber']),
      sugar: safeDouble(json['sugar']),
      saturatedFat: safeDouble(json['saturatedFat']),
      cholesterol: safeDouble(json['cholesterol']),

      // === Khoáng chất (Minerals) ===
      sodium: safeDouble(json['sodium']),
      potassium: safeDouble(json['potassium']),
      calcium: safeDouble(json['calcium']),
      iron: safeDouble(json['iron']),
      magnesium: safeDouble(json['magnesium']),

      // === Vitamins ===
      vitaminA: safeDouble(json['vitaminA']),
      vitaminC: safeDouble(json['vitaminC']),
      vitaminD: safeDouble(json['vitaminD']),
      vitaminE: safeDouble(json['vitaminE']),
      vitaminK: safeDouble(json['vitaminK']),
      vitaminB6: safeDouble(json['vitaminB6']),
      vitaminB12: safeDouble(json['vitaminB12']),
    );
  }
}