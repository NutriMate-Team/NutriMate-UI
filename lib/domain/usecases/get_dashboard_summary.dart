import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../models/dashboard_model.dart'; 

class GetDashboardSummary {
  final DashboardRepository repository;

  GetDashboardSummary(this.repository);

  // Hàm call() cho phép gọi class này như một hàm
  Future<Either<Failure, DashboardModel>> call() async {
    return await repository.getSummary();
  }
}