import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_log_model.dart';
import '../../domain/entities/create_workout_log_dto.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_remote_datasource.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  WorkoutRepositoryImpl({
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ExerciseModel>>> getExercises() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDatasource.getExercises();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createWorkoutLog(CreateWorkoutLogDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDatasource.createWorkoutLog(dto);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }

  @override
  Future<Either<Failure, List<WorkoutLogModel>>> getTodayWorkoutLogs() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDatasource.getTodayWorkoutLogs();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorkoutLog(String logId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDatasource.deleteWorkoutLog(logId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }
}