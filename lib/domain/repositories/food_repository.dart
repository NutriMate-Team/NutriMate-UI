import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../models/food_model.dart';

abstract class FoodRepository {
  Future<Either<Failure, List<FoodModel>>> searchFood(String query);
  Future<Either<Failure, FoodModel>> searchBarcode(String code);
}