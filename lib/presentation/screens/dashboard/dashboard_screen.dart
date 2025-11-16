// file: lib/presentation/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/dashboard_provider.dart';
import '../../../models/dashboard_model.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Tải dữ liệu ngay khi vào màn hình
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
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Điều hướng sang trang Profile
            },
          )
        ],
      ),
      backgroundColor: Colors.grey[50], // Màu nền sạch
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          // ... (Phần code loading, error, success giữ nguyên) ...
          
          // 1. TRẠNG THÁI LOADING
          if (provider.status == DashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. TRẠNG THÁI LỖI
          if (provider.status == DashboardStatus.error) {
            return Center(child: Text('Lỗi: ${provider.errorMessage}'));
          }

          // 3. TRẠNG THÁI THÀNH CÔNG
          if (provider.status == DashboardStatus.success && provider.summary != null) {
            final summary = provider.summary!;

            // Tính toán phần trăm calo
            final double target = summary.targetCalories ?? 2000;
            final double consumed = summary.caloriesConsumed;
            final double remaining = summary.remainingCalories ?? (target - consumed);
            double percent = (consumed / target);
            if (percent < 0) percent = 0;
            if (percent > 1) percent = 1;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BIỂU ĐỒ TRÒN CALO CHÍNH ---
                  CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 14.0,
                    percent: percent,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          remaining.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Calo còn lại",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                    progressColor: Colors.green,
                    backgroundColor: Colors.green.shade100, // (Dòng này OK)
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // --- CHI TIẾT CALO ---
                  _buildCalorieDetailsCard(summary), // (Giờ đã hợp lệ)
                  
                  const SizedBox(height: 16),
                  
                  // --- CHI TIẾT DINH DƯỠNG ---
                  _buildMacroNutrientsCard(),
                ],
              ),
            );
          }

          // 4. TRẠNG THÁI BAN ĐẦU
          return const Center(child: Text('Đang chờ tải dữ liệu...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Điều hướng sang trang tìm kiếm/thêm món ăn
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // (Hàm này giờ đã hợp lệ vì DashboardModel đã được import)
  Widget _buildCalorieDetailsCard(DashboardModel summary) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  Widget _buildMacroNutrientsCard() {
    // TODO: Lấy dữ liệu Protein, Carb, Fat từ `summary`
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMacroRow("Chất đạm (Protein)", 50, 120, Colors.blue),
            const SizedBox(height: 12),
            _buildMacroRow("Chất béo (Fat)", 30, 60, Colors.orange),
            const SizedBox(height: 12),
            _buildMacroRow("Carbs (Tinh bột)", 100, 250, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // 2. (SỬA LỖI 2) Đổi `Color` thành `MaterialColor`
  Widget _buildMacroRow(String label, double consumed, double target, MaterialColor color) {
    double percent = (consumed / target);
    if (percent < 0) percent = 0;
    if (percent > 1) percent = 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text("${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g", style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          percent: percent,
          lineHeight: 10,
          progressColor: color, // Giờ là MaterialColor
          backgroundColor: color.shade100, // (Giờ đã hợp lệ)
          barRadius: const Radius.circular(5),
        ),
      ],
    );
  }
}