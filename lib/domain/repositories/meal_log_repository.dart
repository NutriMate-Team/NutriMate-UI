import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/create_meal_log_dto.dart';
import '../../models/meal_log_model.dart';

abstract class MealLogRepository {
  Future<Either<Failure, void>> createMealLog(CreateMealLogDto dto);
  Future<Either<Failure, List<MealLogModel>>> getMealLogs();
  Future<Either<Failure, void>> deleteMealLog(String id);
}