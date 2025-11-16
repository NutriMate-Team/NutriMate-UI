import 'package:flutter/material.dart';
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../models/dashboard_model.dart';
import '../../core/error/failures.dart';

enum DashboardStatus { initial, loading, success, error }

class DashboardProvider extends ChangeNotifier {
  final GetDashboardSummary getDashboardSummary;

  DashboardStatus _status = DashboardStatus.initial;
  String _errorMessage = '';
  DashboardModel? _summary;

  // Getters cho UI
  DashboardStatus get status => _status;
  String get errorMessage => _errorMessage;
  DashboardModel? get summary => _summary;

  DashboardProvider({required this.getDashboardSummary});

  // 2. Hàm mà UI sẽ gọi
  Future<void> fetchSummary() async {
    _status = DashboardStatus.loading;
    notifyListeners();

    final result = await getDashboardSummary(); // Gọi UseCase

    result.fold(
      // 3. Xử lý Lỗi
      (failure) {
        _status = DashboardStatus.error;
        _errorMessage = (failure is ServerFailure)
            ? failure.message
            : 'Lỗi kết nối';
      },
      // 4. Xử lý Thành công
      (summaryModel) {
        _status = DashboardStatus.success;
        _summary = summaryModel;
        _errorMessage = '';
      },
    );

    notifyListeners(); // Thông báo cho UI cập nhật
  }
}