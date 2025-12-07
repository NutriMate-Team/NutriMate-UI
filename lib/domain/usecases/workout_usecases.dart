import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/workout_repository.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_log_model.dart';
import '../entities/create_workout_log_dto.dart';

class GetExercises {
  final WorkoutRepository repository;
  GetExercises(this.repository);
  Future<Either<Failure, List<ExerciseModel>>> call() async {
    return await repository.getExercises();
  }
}

class CreateWorkoutLog {
  final WorkoutRepository repository;
  CreateWorkoutLog(this.repository);
  Future<Either<Failure, void>> call(CreateWorkoutLogDto dto) async {
    return await repository.createWorkoutLog(dto);
  }
}

class GetTodayWorkoutLogs {
  final WorkoutRepository repository;
  GetTodayWorkoutLogs(this.repository);
  Future<Either<Failure, List<WorkoutLogModel>>> call() async {
    return await repository.getTodayWorkoutLogs();
  }
}

class DeleteWorkoutLog {
  final WorkoutRepository repository;
  DeleteWorkoutLog(this.repository);
  Future<Either<Failure, void>> call(String logId) async {
    return await repository.deleteWorkoutLog(logId);
  }
}