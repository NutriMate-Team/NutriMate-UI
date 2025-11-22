import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/usecases/create_meal_log.dart';
import '../../domain/usecases/get_meal_logs.dart';
import '../../domain/usecases/delete_meal_log.dart';
import '../../domain/entities/create_meal_log_dto.dart';
import '../../models/meal_log_model.dart';
import '../../core/error/failures.dart';
import 'dashboard_provider.dart';

enum MealLogStatus { initial, loading, success, error }

class MealLogProvider extends ChangeNotifier {
  final CreateMealLog createMealLog;
  final GetMealLogs getMealLogs;
  final DeleteMealLog deleteMealLog;

  MealLogStatus _status = MealLogStatus.initial;
  String _errorMessage = '';
  List<MealLogModel> _logs = [];

  MealLogStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<MealLogModel> get logs => _logs;

  MealLogProvider({
    required this.createMealLog,
    required this.getMealLogs,
    required this.deleteMealLog,
  });

  // 1. Lấy danh sách nhật ký
  Future<void> fetchLogs() async {
    _status = MealLogStatus.loading;
    notifyListeners();

    final result = await getMealLogs();

    result.fold(
      (failure) {
        _status = MealLogStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
        _logs = [];
      },
      (data) {
        _status = MealLogStatus.success;
        _logs = data;
      },
    );
    notifyListeners();
  }

  // 2. Lưu nhật ký (Thêm mới)
  // Lưu ý: DTO truyền vào đây đã chứa đủ thông tin USDA (source, name, calories...)
  // nhờ việc chúng ta cập nhật CreateMealLogDto ở bước trước.
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
        success = true;
        fetchLogs(); // Tải lại danh sách ngay sau khi thêm thành công
      },
    );

    notifyListeners();
    return success;
  }

  // 3. Xóa nhật ký
  Future<bool> deleteLog(String id, BuildContext context) async {
    // A. Xóa tạm thời trên giao diện (Optimistic UI) để cảm giác nhanh hơn
    final index = _logs.indexWhere((element) => element.id == id);
    if (index == -1) return false;

    final deletedItem = _logs[index];
    _logs.removeAt(index);
    notifyListeners(); 

    // B. Gọi UseCase Xóa xuống Backend
    final result = await deleteMealLog(id);

    bool success = true;

    result.fold(
      (failure) {
        // C. Nếu lỗi -> Hoàn tác (Thêm lại item vào chỗ cũ)
        _logs.insert(index, deletedItem);
        _errorMessage = "Xóa thất bại: ${failure is ServerFailure ? failure.message : 'Lỗi mạng'}";
        notifyListeners();
        success = false;
      },
      (_) {
        // D. Nếu thành công -> Cập nhật lại Dashboard (Calo tổng)
        if (context.mounted) {
          Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
        }
        success = true;
      },
    );

    return success;
  }
}