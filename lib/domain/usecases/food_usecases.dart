import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/food_repository.dart';
import '../../models/food_model.dart';

class SearchFood {
  final FoodRepository repository;
  SearchFood(this.repository);

  Future<Either<Failure, List<FoodModel>>> call(String query) async {
    return await repository.searchFood(query);
  }
}

class SearchBarcode {
  final FoodRepository repository;
  SearchBarcode(this.repository);

  Future<Either<Failure, FoodModel>> call(String code) async {
    return await repository.searchBarcode(code);
  }
}