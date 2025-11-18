import 'package:flutter/material.dart';
import '../../domain/usecases/workout_usecases.dart';
import '../../models/exercise_model.dart';
import '../../domain/entities/create_workout_log_dto.dart';
import '../../core/error/failures.dart';

enum WorkoutStatus { initial, loading, success, error }

class WorkoutProvider extends ChangeNotifier {
  final GetExercises getExercises;
  final CreateWorkoutLog createWorkoutLog;

  WorkoutStatus _status = WorkoutStatus.initial;
  String _errorMessage = '';
  List<ExerciseModel> _exercises = [];

  WorkoutStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<ExerciseModel> get exercises => _exercises;

  WorkoutProvider({
    required this.getExercises,
    required this.createWorkoutLog,
  });

  // Lấy danh sách bài tập
  Future<void> fetchExercises() async {
    _status = WorkoutStatus.loading;
    notifyListeners();

    final result = await getExercises();
    result.fold(
      (failure) {
        _status = WorkoutStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
      },
      (data) {
        _status = WorkoutStatus.success;
        _exercises = data;
      },
    );
    notifyListeners();
  }

  // Lưu log tập luyện
  Future<bool> saveLog(CreateWorkoutLogDto dto) async {
    _status = WorkoutStatus.loading;
    notifyListeners();

    final result = await createWorkoutLog(dto);
    bool success = false;

    result.fold(
      (failure) {
        _status = WorkoutStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
        success = false;
      },
      (_) {
        _status = WorkoutStatus.success;
        success = true;
      },
    );

    notifyListeners();
    return success;
  }
}