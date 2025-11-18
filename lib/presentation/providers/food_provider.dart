import 'package:flutter/material.dart';
import '../../domain/usecases/food_usecases.dart';
import '../../models/food_model.dart';
import '../../core/error/failures.dart';

enum FoodStatus { initial, loading, success, error }

class FoodProvider extends ChangeNotifier {
  final SearchFood searchFood;
  final SearchBarcode searchBarcode;

  FoodStatus _status = FoodStatus.initial;
  String _errorMessage = '';
  List<FoodModel> _searchResults = [];
  FoodModel? _barcodeResult;

  // Getters
  FoodStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<FoodModel> get searchResults => _searchResults;
  FoodModel? get barcodeResult => _barcodeResult;

  FoodProvider({
    required this.searchFood,
    required this.searchBarcode,
  });

  // Hàm tìm kiếm theo Tên
  Future<void> search(String query) async {
    _status = FoodStatus.loading;
    _barcodeResult = null; // Xóa kết quả barcode cũ
    notifyListeners();

    final result = await searchFood(query);
    result.fold(
      (failure) {
        _status = FoodStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
        _searchResults = [];
      },
      (foods) {
        _status = FoodStatus.success;
        _searchResults = foods;
      },
    );
    notifyListeners();
  }

  // Hàm tìm kiếm theo Barcode
  Future<void> scan(String code) async {
    _status = FoodStatus.loading;
    _searchResults = []; // Xóa kết quả tìm kiếm cũ
    notifyListeners();

    final result = await searchBarcode(code);
    result.fold(
      (failure) {
        _status = FoodStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
        _barcodeResult = null;
      },
      (food) {
        _status = FoodStatus.success;
        _barcodeResult = food;
      },
    );
    notifyListeners();
  }
}