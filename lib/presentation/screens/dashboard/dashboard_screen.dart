
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

// Providers & Models
import '../../providers/dashboard_provider.dart';
import '../../../models/dashboard_model.dart';

// Screens
import 'package:nutri_mate_ui/presentation/screens/workout/workout_screen.dart';
import 'package:nutri_mate_ui/presentation/screens/meal_diary/meal_diary_screen.dart';

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
        // Chỉ giữ lại nút Workout trên AppBar
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
          // 1. LOADING
          if (provider.status == DashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. ERROR
          if (provider.status == DashboardStatus.error) {
            return Center(child: Text('Lỗi: ${provider.errorMessage}'));
          }
          // 3. SUCCESS
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
                  // --- BIỂU ĐỒ TRÒN ---
                  CircularPercentIndicator(
                    radius: 120.0, 
                    lineWidth: 14.0, 
                    percent: percent,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          remaining.toStringAsFixed(0), 
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)
                        ),
                        const Text("Calo còn lại", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                    progressColor: Colors.green, 
                    backgroundColor: Colors.green.shade100, 
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // --- THẺ CHI TIẾT CALO ---
                  _buildCalorieDetailsCard(summary),
                  
                  const SizedBox(height: 12),

                  // --- NÚT XEM NHẬT KÝ (MỚI) ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MealDiaryScreen()),
                        );
                      },
                      icon: const Icon(Icons.history, size: 20),
                      label: const Text("Xem nhật ký ăn uống"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // --- THẺ NƯỚC UỐNG (XỊN) ---
                  _buildWaterTrackerCard(provider),

                  const SizedBox(height: 16),
                  
                  // --- THẺ MACRO ---
                  _buildMacroNutrientsCard(),
                ],
              ),
            );
          }
          return const Center(child: Text('Đang chờ tải dữ liệu...'));
        },
      ),
    );
  }

  // --- CÁC WIDGET CON ---

  Widget _buildWaterTrackerCard(DashboardProvider provider) {
    int glasses = provider.waterGlasses;
    int target = 8; 
    int mlPerGlass = 250; 
    int currentMl = glasses * mlPerGlass;
    int targetMl = target * mlPerGlass;
    double percent = glasses / target;
    if (percent > 1) percent = 1;

    return Card(
      elevation: 2,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Nước uống", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("$currentMl / $targetMl ml", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 20.0,
              percent: percent,
              backgroundColor: Colors.blue.shade50,
              progressColor: Colors.blue,
              barRadius: const Radius.circular(10),
              animation: true,
              center: Text("$glasses cốc", style: TextStyle(fontSize: 12, color: percent > 0.5 ? Colors.white : Colors.black)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircleButton(
                  icon: Icons.remove,
                  onTap: () => provider.updateWater(-1),
                  color: Colors.grey,
                ),
                const SizedBox(width: 30), 
                _buildCircleButton(
                  icon: Icons.add,
                  onTap: () => provider.updateWater(1),
                  color: Colors.blue,
                  isLarge: true, 
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap, required Color color, bool isLarge = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(isLarge ? 12 : 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1), 
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: isLarge ? 32 : 24),
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

  Widget _buildMacroNutrientsCard() {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMacroRow(String label, double consumed, double target, MaterialColor color) {
    double percent = (consumed / target);
    if (percent < 0) percent = 0; if (percent > 1) percent = 1;
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
        LinearPercentIndicator(percent: percent, lineHeight: 10, progressColor: color, backgroundColor: color.shade100, barRadius: const Radius.circular(5)),
      ],
    );
  }
}