import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../domain/usecases/workout_usecases.dart';
import '../../models/dashboard_model.dart';
import '../../models/workout_log_model.dart';
import '../../core/error/failures.dart';

enum DashboardStatus { initial, loading, success, error }

class DashboardProvider extends ChangeNotifier {
  final GetDashboardSummary getDashboardSummary;
  final GetTodayWorkoutLogs getTodayWorkoutLogs;
  final DeleteWorkoutLog deleteWorkoutLog;

  DashboardStatus _status = DashboardStatus.initial;
  String _errorMessage = '';
  DashboardModel? _summary;
  
  int _waterGlasses = 0;
  List<WorkoutLogModel> _todayWorkoutLogs = [];
  bool _isLoadingWorkoutLogs = false;

  DashboardStatus get status => _status;
  String get errorMessage => _errorMessage;
  DashboardModel? get summary => _summary;
  int get waterGlasses => _waterGlasses; // Getter cho UI
  List<WorkoutLogModel> get todayWorkoutLogs => _todayWorkoutLogs;
  bool get isLoadingWorkoutLogs => _isLoadingWorkoutLogs;
  
  // Calculate total calories burned today
  double get totalCaloriesBurnedToday {
    return _todayWorkoutLogs.fold(0.0, (sum, log) => sum + log.caloriesBurned);
  }

  DashboardProvider({
    required this.getDashboardSummary,
    required this.getTodayWorkoutLogs,
    required this.deleteWorkoutLog,
  });

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

  // Update water by ml amount (converts ml to glasses)
  Future<void> updateWaterByMl(int ml, {bool isAdd = true}) async {
    const int mlPerGlass = 250;
    // Convert ml to glasses (round to nearest)
    int glassesChange = (ml / mlPerGlass).round();
    if (!isAdd) glassesChange = -glassesChange;
    
    await updateWater(glassesChange);
  }

  Future<void> fetchSummary() async {
    print("--- BẮT ĐẦU FETCH SUMMARY ---");
    _status = DashboardStatus.loading;
    notifyListeners();

    // Tải song song cả API và Water Log
    await loadWaterLog(); 
    print("--- ĐÃ LOAD NƯỚC XONG ---");

    // Fetch summary and workout logs in parallel
    final summaryResult = await getDashboardSummary();
    await fetchTodayWorkoutLogs();

    summaryResult.fold(
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

  // Fetch today's workout logs
  Future<void> fetchTodayWorkoutLogs() async {
    _isLoadingWorkoutLogs = true;
    notifyListeners();

    final result = await getTodayWorkoutLogs();
    result.fold(
      (failure) {
        // Don't set error status for workout logs, just log it
        _todayWorkoutLogs = [];
      },
      (logs) {
        _todayWorkoutLogs = logs;
      },
    );

    _isLoadingWorkoutLogs = false;
    notifyListeners();
  }

  // Delete a workout log
  Future<bool> deleteWorkoutLogEntry(String logId) async {
    final result = await deleteWorkoutLog(logId);
    
    return result.fold(
      (failure) {
        _errorMessage = (failure is ServerFailure)
            ? failure.message
            : 'Lỗi xóa bài tập';
        notifyListeners();
        return false;
      },
      (_) {
        // Remove from local list
        _todayWorkoutLogs.removeWhere((log) => log.id == logId);
        // Refresh summary to update calories burned
        fetchSummary();
        return true;
      },
    );
  }

  // Refresh workout logs after adding a new one
  Future<void> refreshWorkoutLogs() async {
    await fetchTodayWorkoutLogs();
    await fetchSummary();
  }
}