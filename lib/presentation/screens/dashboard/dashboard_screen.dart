import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/dashboard_provider.dart';
import '../../../models/dashboard_model.dart';
import 'package:nutri_mate_ui/presentation/screens/workout/workout_screen.dart';
import 'package:nutri_mate_ui/presentation/screens/food_search/food_search_screen.dart'; // Import màn hình tìm kiếm

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan hôm nay'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center),
            tooltip: 'Luyện tập',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WorkoutScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.status == DashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.status == DashboardStatus.error) {
            return Center(child: Text('Lỗi: ${provider.errorMessage}'));
          }
          if (provider.status == DashboardStatus.success && provider.summary != null) {
            final summary = provider.summary!;
            final double target = summary.targetCalories ?? 2000;
            final double consumed = summary.caloriesConsumed;
            final double remaining = summary.remainingCalories ?? (target - consumed);
            double percent = (consumed / target);
            if (percent < 0) percent = 0; 
            if (percent > 1) percent = 1;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularPercentIndicator(
                    radius: 120.0, 
                    lineWidth: 14.0, 
                    percent: percent,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(remaining.toStringAsFixed(0), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                        const Text("Calo còn lại", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                    progressColor: Colors.green, 
                    backgroundColor: Colors.green.shade100, 
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 24),
                  _buildCalorieDetailsCard(summary),
                ],
              ),
            );
          }
          return const Center(child: Text('Đang chờ tải dữ liệu...'));
        },
      ),
      
      // Nút thêm món ăn (Giữ lại cho bạn dùng)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FoodSearchScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalorieDetailsCard(DashboardModel summary) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn("Mục tiêu", summary.targetCalories?.toStringAsFixed(0) ?? 'N/A', Colors.green),
            _buildStatColumn("Đã nạp", summary.caloriesConsumed.toStringAsFixed(0), Colors.blue),
            _buildStatColumn("Đã đốt", summary.caloriesBurned.toStringAsFixed(0), Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}