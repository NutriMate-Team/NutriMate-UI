import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/meal_log_repository.dart';
import '../../models/meal_log_model.dart';

class GetMealLogs {
  final MealLogRepository repository;

  GetMealLogs(this.repository);

  Future<Either<Failure, List<MealLogModel>>> call() async {
    return await repository.getMealLogs();
  }
}