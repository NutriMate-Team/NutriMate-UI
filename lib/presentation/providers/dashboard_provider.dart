import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../models/dashboard_model.dart';
import '../../core/error/failures.dart';

enum DashboardStatus { initial, loading, success, error }

class DashboardProvider extends ChangeNotifier {
  final GetDashboardSummary getDashboardSummary;

  DashboardStatus _status = DashboardStatus.initial;
  String _errorMessage = '';
  DashboardModel? _summary;
  
  int _waterGlasses = 0; 

  DashboardStatus get status => _status;
  String get errorMessage => _errorMessage;
  DashboardModel? get summary => _summary;
  int get waterGlasses => _waterGlasses; // Getter cho UI

  DashboardProvider({required this.getDashboardSummary});

  Future<void> loadWaterLog() async {
    final prefs = await SharedPreferences.getInstance();
    // Lấy ngày hôm nay (để reset nước mỗi ngày mới)
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String? lastDate = prefs.getString('water_date');

    if (lastDate != today) {
      // Nếu là ngày mới -> Reset về 0
      _waterGlasses = 0;
      await prefs.setString('water_date', today);
      await prefs.setInt('water_count', 0);
    } else {
      // Nếu cùng ngày -> Lấy số cũ
      _waterGlasses = prefs.getInt('water_count') ?? 0;
    }
    notifyListeners();
  }

  Future<void> updateWater(int change) async {
    int newCount = _waterGlasses + change;
    if (newCount < 0) newCount = 0; // Không được âm
    // Giới hạn 20 cốc/ngày
    if (newCount > 20) newCount = 20; 

    _waterGlasses = newCount;
    notifyListeners(); 

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_count', _waterGlasses);
  }

  Future<void> fetchSummary() async {
    print("--- BẮT ĐẦU FETCH SUMMARY ---");
    _status = DashboardStatus.loading;
    notifyListeners();

    // Tải song song cả API và Water Log
    await loadWaterLog(); 
    print("--- ĐÃ LOAD NƯỚC XONG ---");

    final result = await getDashboardSummary();
    

    result.fold(
      (failure) {
        _status = DashboardStatus.error;
        _errorMessage = (failure is ServerFailure)
            ? failure.message
            : 'Lỗi kết nối';
      },
      (summaryModel) {
        _status = DashboardStatus.success;
        _summary = summaryModel;
        _errorMessage = '';
      },
    );

    notifyListeners();
  }
}