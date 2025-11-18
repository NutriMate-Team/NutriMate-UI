import 'package:flutter/material.dart';
import '../../domain/usecases/create_meal_log.dart';
import '../../domain/entities/create_meal_log_dto.dart';
import '../../core/error/failures.dart';

enum MealLogStatus { initial, loading, success, error }

class MealLogProvider extends ChangeNotifier {
  final CreateMealLog createMealLog;

  MealLogStatus _status = MealLogStatus.initial;
  String _errorMessage = '';

  // Getters
  MealLogStatus get status => _status;
  String get errorMessage => _errorMessage;

  MealLogProvider({required this.createMealLog});

  // Hàm mà UI sẽ gọi
  Future<bool> saveLog(CreateMealLogDto dto) async {
    _status = MealLogStatus.loading;
    notifyListeners();

    final result = await createMealLog(dto);
    bool success = false;

    result.fold(
      (failure) {
        _status = MealLogStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
        success = false;
      },
      (_) {
        _status = MealLogStatus.success;
        _errorMessage = '';
        success = true;
      },
    );

    notifyListeners();
    return success; 
  }
}