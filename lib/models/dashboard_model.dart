class DashboardModel {
  final String date;
  final double caloriesConsumed;
  final double caloriesBurned;
  final double netCalories;
  final double? targetCalories; 
  final double? remainingCalories; 
  final double? bmi; 

  DashboardModel({
    required this.date,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.netCalories,
    this.targetCalories,
    this.remainingCalories,
    this.bmi,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      date: json['date'] as String,
      
      // Các trường này luôn có
      caloriesConsumed: (json['caloriesConsumed'] as num? ?? 0).toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num? ?? 0).toDouble(),
      netCalories: (json['netCalories'] as num? ?? 0).toDouble(),

      // Các trường này có thể là null
      targetCalories: (json['targetCalories'] as num?)?.toDouble(),
      remainingCalories: (json['remainingCalories'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
    );
  }
}