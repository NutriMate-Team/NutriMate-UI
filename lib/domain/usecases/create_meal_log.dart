import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/meal_log_repository.dart';
import '../entities/create_meal_log_dto.dart';

class CreateMealLog {
  final MealLogRepository repository;

  CreateMealLog(this.repository);

  Future<Either<Failure, void>> call(CreateMealLogDto dto) async {
    return await repository.createMealLog(dto);
  }
}