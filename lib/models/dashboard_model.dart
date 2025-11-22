class DashboardModel {
  final String date;
  final double caloriesConsumed;
  final double caloriesBurned;
  final double netCalories;
  final double? targetCalories;
  final double? remainingCalories;
  final double? bmi;
  
  // --- THÊM CÁC TRƯỜNG NÀY ---
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;

  DashboardModel({
    required this.date,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.netCalories,
    this.targetCalories,
    this.remainingCalories,
    this.bmi,
    // --- THÊM VÀO CONSTRUCTOR ---
    this.totalProtein = 0,
    this.totalFat = 0,
    this.totalCarbs = 0,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      date: json['date'] as String,
      caloriesConsumed: (json['caloriesConsumed'] as num? ?? 0).toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num? ?? 0).toDouble(),
      netCalories: (json['netCalories'] as num? ?? 0).toDouble(),
      targetCalories: (json['targetCalories'] as num?)?.toDouble(),
      remainingCalories: (json['remainingCalories'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      
      // --- ĐỌC DỮ LIỆU TỪ JSON ---
      totalProtein: (json['totalProtein'] as num? ?? 0).toDouble(),
      totalFat: (json['totalFat'] as num? ?? 0).toDouble(),
      totalCarbs: (json['totalCarbs'] as num? ?? 0).toDouble(),
    );
  }
}