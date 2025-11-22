import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/meal_log_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../models/meal_log_model.dart';

class MealDiaryScreen extends StatefulWidget {
  const MealDiaryScreen({super.key});

  @override
  State<MealDiaryScreen> createState() => _MealDiaryScreenState();
}

class _MealDiaryScreenState extends State<MealDiaryScreen> {
  @override
  void initState() {
    super.initState();
    // Tải dữ liệu khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealLogProvider>(context, listen: false).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nhật ký ăn uống',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<MealLogProvider>(
        builder: (context, provider, child) {
          // 1. Loading
          if (provider.status == MealLogStatus.loading && provider.logs.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          }

          // 2. Error
          if (provider.status == MealLogStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${provider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          // Calculate total calories and get goal
          final totalCalories = provider.logs.fold<double>(
            0,
            (sum, log) => sum + (log.totalCalories ?? 0),
          );
          
          // Get goal from dashboard provider
          final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
          final goalCalories = dashboardProvider.summary?.targetCalories ?? 2000;

          // 3. Empty
          if (provider.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_meals, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhật ký hôm nay',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600], 
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group logs by meal type
          final groupedLogs = _groupLogsByMealType(provider.logs);

          // 4. List Data (Có Refresh) with grouping
          return RefreshIndicator(
            onRefresh: () => provider.fetchLogs(),
            color: Colors.green,
            child: Column(
              children: [
                // Header với Total Calories vs Goal
                _buildHeaderCard(totalCalories, goalCalories),
                // List of meal logs grouped by type
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: groupedLogs.length,
                    itemBuilder: (context, index) {
                      final entry = groupedLogs[index];
                      final mealType = entry['type'] as String;
                      final logs = entry['logs'] as List<MealLogModel>;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sticky header for meal type
                          _buildMealTypeHeader(mealType, logs),
                          const SizedBox(height: 8),
                          // Logs for this meal type
                          ...logs.map((log) => _buildLogItem(log, provider)),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Group logs by meal type
  List<Map<String, dynamic>> _groupLogsByMealType(List<MealLogModel> logs) {
    final Map<String, List<MealLogModel>> grouped = {};
    
    for (var log in logs) {
      final type = log.mealType;
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(log);
    }
    
    // Order: Breakfast, Lunch, Dinner, Snack
    final order = ['Bữa sáng', 'Bữa trưa', 'Bữa tối', 'Ăn nhẹ'];
    final result = <Map<String, dynamic>>[];
    
    for (var type in order) {
      if (grouped.containsKey(type)) {
        result.add({'type': type, 'logs': grouped[type]!});
      }
    }
    
    // Add any other types not in the standard order
    for (var entry in grouped.entries) {
      if (!order.contains(entry.key)) {
        result.add({'type': entry.key, 'logs': entry.value});
      }
    }
    
    return result;
  }

  // Header Card showing total calories vs goal
  Widget _buildHeaderCard(double totalCalories, double goalCalories) {
    final percent = (totalCalories / goalCalories).clamp(0.0, 1.0);
    final remaining = goalCalories - totalCalories;
    final isOverGoal = totalCalories > goalCalories;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverGoal
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOverGoal ? Colors.orange : Colors.green).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng calo hôm nay',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    totalCalories.toStringAsFixed(0),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mục tiêu: ${goalCalories.toStringAsFixed(0)} kcal',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                isOverGoal
                    ? 'Vượt ${(totalCalories - goalCalories).toStringAsFixed(0)} kcal'
                    : 'Còn ${remaining.toStringAsFixed(0)} kcal',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Meal type header (sticky-like appearance)
  Widget _buildMealTypeHeader(String mealType, List<MealLogModel> logs) {
    final totalForType = logs.fold<double>(
      0,
      (sum, log) => sum + (log.totalCalories ?? 0),
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _getMealTypeColor(mealType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getMealTypeColor(mealType).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getMealTypeIcon(mealType),
            color: _getMealTypeColor(mealType),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            mealType,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getMealTypeColor(mealType),
            ),
          ),
          const Spacer(),
          Text(
            '${totalForType.toStringAsFixed(0)} kcal',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getMealTypeColor(mealType),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '• ${logs.length} món',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(MealLogModel log, MealLogProvider provider) {
    // Format ngày giờ
    String timeStr = "00:00";
    String dateStr = "Today";
    try {
      timeStr = DateFormat('HH:mm').format(log.loggedAt.toLocal());
      dateStr = DateFormat('dd/MM').format(log.loggedAt.toLocal());
    } catch (e) {
      // Fallback nếu lỗi format
    }

    return Dismissible(
      key: Key(log.id), // Key duy nhất để xác định item xóa
      direction: DismissDirection.endToStart, // Chỉ vuốt từ Phải sang Trái
      
      // Giao diện Thùng rác (hiện ra khi vuốt) - Improved design
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Xóa",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      
      // Logic khi vuốt xong
      onDismissed: (direction) {
        provider.deleteLog(log.id, context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${log.food?.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },

      // Giao diện thẻ món ăn (Custom Card Design)
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image/Icon placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getMealTypeColor(log.mealType).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getMealTypeIcon(log.mealType),
                    color: _getMealTypeColor(log.mealType),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Food details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.food?.name ?? 'Món ăn',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getMealTypeColor(log.mealType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.mealType,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getMealTypeColor(log.mealType),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${log.quantity.toStringAsFixed(0)} g',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$timeStr • $dateStr',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Calories (Bold, Right-aligned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${log.totalCalories?.toStringAsFixed(0) ?? 0}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMealTypeColor(String type) {
    switch (type) {
      case 'Bữa sáng': return Colors.orange;
      case 'Bữa trưa': return Colors.blue;
      case 'Bữa tối': return Colors.purple;
      case 'Ăn nhẹ': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getMealTypeIcon(String type) {
    switch (type) {
      case 'Bữa sáng': return Icons.wb_sunny;
      case 'Bữa trưa': return Icons.lunch_dining;
      case 'Bữa tối': return Icons.dinner_dining;
      case 'Ăn nhẹ': return Icons.cookie;
      default: return Icons.restaurant;
    }
  }
}