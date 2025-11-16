import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../../models/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardModel>> getSummary() async {
    if (await networkInfo.isConnected) {
      try {
        final summary = await remoteDatasource.getSummary();
        return Right(summary); 
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message)); 
      }
    } else {
      return Left(const ConnectionFailure()); 
    }
  }
}