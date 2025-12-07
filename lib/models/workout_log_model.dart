import 'exercise_model.dart';

class WorkoutLogModel {
  final String id;
  final String userId;
  final String exerciseId;
  final double durationMin;
  final double caloriesBurned;
  final DateTime loggedAt;
  final ExerciseModel? exercise;

  WorkoutLogModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.durationMin,
    required this.caloriesBurned,
    required this.loggedAt,
    this.exercise,
  });

  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) {
    return WorkoutLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      exerciseId: json['exerciseId'] as String,
      durationMin: (json['durationMin'] as num).toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
      loggedAt: DateTime.parse(json['loggedAt']),
      // Parse exercise info if available
      exercise: json['exercise'] != null
          ? ExerciseModel.fromJson(json['exercise'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'exerciseId': exerciseId,
      'durationMin': durationMin,
      'caloriesBurned': caloriesBurned,
      'loggedAt': loggedAt.toIso8601String(),
      'exercise': exercise?.toJson(),
    };
  }
}

