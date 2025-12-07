class ProfileModel {
  final String userId;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String? activityLevel; 
  final double? bmi;
  final String? goalStartDate; // ISO date string (YYYY-MM-DD)
  final double? weeklyGoalRate; // kg per week
  final String? profilePictureUrl; // User's profile picture URL

  ProfileModel({
    required this.userId,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.bmi,
    this.goalStartDate,
    this.weeklyGoalRate,
    this.profilePictureUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['userId'] as String,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] as String?,
      bmi: (json['bmi'] as num?)?.toDouble(),
      goalStartDate: json['goalStartDate'] as String?,
      weeklyGoalRate: (json['weeklyGoalRate'] as num?)?.toDouble(),
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }
}