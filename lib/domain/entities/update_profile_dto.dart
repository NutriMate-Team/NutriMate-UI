enum ActivityLevel {
  SEDENTARY, // Ít vận động
  LIGHT, // Vận động nhẹ
  MODERATE, // Vận động vừa
  ACTIVE, // Năng động
  VERY_ACTIVE, // Rất năng động
}

class UpdateProfileDto {
  final double? weightKg;
  final double? heightCm;
  final double? targetWeightKg;
  final String? activityLevel; // "SEDENTARY", "LIGHT", v.v.
  final String? goalStartDate; // ISO date string (YYYY-MM-DD)
  final double? weeklyGoalRate; // kg per week

  UpdateProfileDto({
    this.weightKg,
    this.heightCm,
    this.targetWeightKg,
    this.activityLevel,
    this.goalStartDate,
    this.weeklyGoalRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'heightCm': heightCm,
      'targetWeightKg': targetWeightKg,
      'activityLevel': activityLevel,
      'goalStartDate': goalStartDate,
      'weeklyGoalRate': weeklyGoalRate,
    }..removeWhere((key, value) => value == null); 
  }
}