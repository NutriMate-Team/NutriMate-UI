import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../models/food_model.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/food_remote_datasource.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  FoodRepositoryImpl({
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<FoodModel>>> searchFood(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final foods = await remoteDatasource.searchFood(query);
        return Right(foods);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }
  
  @override
  Future<Either<Failure, FoodModel>> searchBarcode(String code) async {
     if (await networkInfo.isConnected) {
      try {
        final food = await remoteDatasource.searchBarcode(code);
        return Right(food);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }
}