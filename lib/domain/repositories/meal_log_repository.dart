import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/create_meal_log_dto.dart';

abstract class MealLogRepository {
  Future<Either<Failure, void>> createMealLog(CreateMealLogDto dto);
}