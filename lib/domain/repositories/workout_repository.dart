import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../models/exercise_model.dart';
import '../entities/create_workout_log_dto.dart';

abstract class WorkoutRepository {
  Future<Either<Failure, List<ExerciseModel>>> getExercises();
  Future<Either<Failure, void>> createWorkoutLog(CreateWorkoutLogDto dto);
}