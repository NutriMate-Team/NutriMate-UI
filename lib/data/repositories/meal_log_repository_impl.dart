import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/create_meal_log_dto.dart';
import '../../domain/repositories/meal_log_repository.dart';
import '../datasources/meal_log_remote_datasource.dart';

class MealLogRepositoryImpl implements MealLogRepository {
  final MealLogRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  MealLogRepositoryImpl({
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> createMealLog(CreateMealLogDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDatasource.createMealLog(dto);
        return const Right(null); // Thành công, trả về Right(void)
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }
}