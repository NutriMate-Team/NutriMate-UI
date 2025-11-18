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

  UpdateProfileDto({
    this.weightKg,
    this.heightCm,
    this.targetWeightKg,
    this.activityLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'heightCm': heightCm,
      'targetWeightKg': targetWeightKg,
      'activityLevel': activityLevel,
    }..removeWhere((key, value) => value == null); 
  }
}