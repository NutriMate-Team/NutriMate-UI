class ExerciseModel {
  final String id;
  final String name;
  final double caloriesBurnedPerHour;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.caloriesBurnedPerHour,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      caloriesBurnedPerHour: (json['caloriesBurnedPerHour'] as num? ?? 0).toDouble(),
    );
  }
}