import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/meal_log_repository.dart';

class DeleteMealLog {
  final MealLogRepository repository;

  DeleteMealLog(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteMealLog(id);
  }
}