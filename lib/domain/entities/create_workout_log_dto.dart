class CreateWorkoutLogDto {
  final String exerciseId;
  final double durationMin;

  CreateWorkoutLogDto({
    required this.exerciseId,
    required this.durationMin,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'durationMin': durationMin,
    };
  }
}