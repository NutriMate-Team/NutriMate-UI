import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../models/dashboard_model.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardModel>> getSummary();
}