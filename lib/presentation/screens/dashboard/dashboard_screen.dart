import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

// Providers & Models
import '../../providers/dashboard_provider.dart';
import '../../../models/dashboard_model.dart';

// Screens
import 'package:nutri_mate_ui/presentation/screens/workout/workout_screen.dart';
import 'package:nutri_mate_ui/presentation/screens/meal_diary/meal_diary_screen.dart';
import 'package:nutri_mate_ui/presentation/screens/food_search/food_search_screen.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tổng quan hôm nay',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            tooltip: 'Hồ sơ',
            onPressed: () {
              // Navigate to profile or show menu
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          // 1. LOADING with animation
          if (provider.status == DashboardStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          }
          // 2. ERROR
          if (provider.status == DashboardStatus.error) {
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
          // 3. SUCCESS
          if (provider.status == DashboardStatus.success && provider.summary != null) {
            final summary = provider.summary!;
            final double target = summary.targetCalories ?? 2000;
            final double consumed = summary.caloriesConsumed;
            final double remaining = summary.remainingCalories ?? (target - consumed);
            double percent = (consumed / target);
            if (percent < 0) percent = 0; 
            if (percent > 1) percent = 1;

            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- BIỂU ĐỒ TRÒN VỚI FIRE ICON (HERO SECTION) ---
                    _buildCalorieProgressIndicator(remaining, percent, consumed, target, summary.caloriesBurned),
                    
                    const SizedBox(height: 24),
                    
                    // --- QUICK ADD SECTION ---
                    _buildQuickAddSection(context),
                    
                    const SizedBox(height: 16),
                    
                    // --- THẺ CHI TIẾT CALO ---
                    _buildCalorieDetailsCard(summary),
                    
                    const SizedBox(height: 12),

                    // --- NÚT XEM NHẬT KÝ ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MealDiaryScreen()),
                            );
                          },
                          icon: const Icon(Icons.history, size: 20),
                          label: Text(
                            "Xem nhật ký ăn uống",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // --- THẺ NƯỚC UỐNG (GLASS FILLING EFFECT) ---
                    _buildWaterTrackerCard(provider),

                    const SizedBox(height: 16),
                    
                    // --- THẺ MACRO ---
                    _buildMacroNutrientsCard(),
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('Đang chờ tải dữ liệu...'));
        },
      ),
    );
  }

  // --- CÁC WIDGET CON ---

  // Circular Progress Indicator với Fire Icon - Hero Section
  Widget _buildCalorieProgressIndicator(double remaining, double percent, double consumed, double target, double burned) {
    // Dynamic flame color based on progress
    Color flameColor = percent < 0.5 
        ? Colors.orange.shade600 
        : percent < 0.8 
            ? Colors.deepOrange.shade600 
            : Colors.red.shade600;
    
    return Hero(
      tag: 'calorie_progress',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            // Stats around the circle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge(
                  label: 'Đã nạp',
                  value: consumed.toStringAsFixed(0),
                  color: Colors.blue,
                  icon: Icons.restaurant,
                ),
                _buildStatBadge(
                  label: 'Đã đốt',
                  value: burned.toStringAsFixed(0),
                  color: Colors.orange,
                  icon: Icons.local_fire_department,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Circular Progress with center content
            Stack(
              alignment: Alignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 140.0, 
                  lineWidth: 18.0, 
                  percent: percent,
                  animation: true,
                  animateFromLastPercent: true,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dynamic Fire Icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: flameColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          color: flameColor,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        remaining.toStringAsFixed(0), 
                        style: GoogleFonts.poppins(
                          fontSize: 48, 
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        "Calo còn lại", 
                        style: GoogleFonts.poppins(
                          fontSize: 14, 
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mục tiêu: ${target.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  progressColor: Colors.green.shade600, 
                  backgroundColor: Colors.green.shade50, 
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Remaining calories badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: remaining > 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: remaining > 0 ? Colors.green.shade200 : Colors.red.shade200,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    remaining > 0 ? Icons.check_circle : Icons.warning,
                    color: remaining > 0 ? Colors.green.shade700 : Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    remaining > 0 
                        ? 'Còn ${remaining.toStringAsFixed(0)} calo để đạt mục tiêu'
                        : 'Đã vượt mục tiêu ${(-remaining).toStringAsFixed(0)} calo',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: remaining > 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({required String label, required String value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Add Section - Horizontal Scrollable
  Widget _buildQuickAddSection(BuildContext context) {
    final quickActions = [
      {'name': 'Bữa sáng', 'icon': Icons.wb_sunny, 'color': Colors.orange},
      {'name': 'Bữa trưa', 'icon': Icons.lunch_dining, 'color': Colors.blue},
      {'name': 'Bữa tối', 'icon': Icons.dinner_dining, 'color': Colors.purple},
      {'name': 'Ăn nhẹ', 'icon': Icons.cookie, 'color': Colors.green},
      {'name': 'Nước', 'icon': Icons.water_drop, 'color': Colors.cyan},
      {'name': 'Luyện tập', 'icon': Icons.fitness_center, 'color': Colors.red},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Thêm nhanh',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: quickActions.length,
                itemBuilder: (context, index) {
                  final action = quickActions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildQuickAddButton(
                      context: context,
                      label: action['name'] as String,
                      icon: action['icon'] as IconData,
                      color: action['color'] as Color,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return _ScaleOnTap(
      onTap: () {
        if (label == 'Luyện tập') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const WorkoutScreen()),
          );
        } else if (label == 'Nước') {
          // Scroll to water section or show water dialog
          // For now, just navigate to dashboard (water is on dashboard)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vuốt xuống để xem phần nước uống'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FoodSearchScreen(),
            ),
          );
        }
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.water_drop, color: Colors.cyan.shade600, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  "Nước uống", 
                  style: GoogleFonts.poppins(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Water amount text (prominently displayed)
            Center(
              child: Text(
                "$currentMl / $targetMl ml",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Linear Progress Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 15,
                backgroundColor: Colors.cyan.shade50,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade600),
              ),
            ),
            const SizedBox(height: 20),
            // Quick Add buttons as rounded chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWaterChipButton(
                  label: '+250ml',
                  onTap: () => provider.updateWater(1),
                  color: Colors.cyan,
                ),
                const SizedBox(width: 12),
                _buildWaterChipButton(
                  label: '+500ml',
                  onTap: () => provider.updateWater(2),
                  color: Colors.cyan,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterChipButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCalorieDetailsCard(DashboardModel summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    // Lấy dữ liệu từ Provider
    final summary = Provider.of<DashboardProvider>(context).summary;
    if (summary == null) return const SizedBox(); // An toàn

    // Lấy dữ liệu THỰC TẾ đã ăn
    final double currentProtein = summary.totalProtein;
    final double currentFat = summary.totalFat;
    final double currentCarb = summary.totalCarbs;

    // Tính toán MỤC TIÊU dựa trên Calo (Công thức giả định: 30% P - 25% F - 45% C)
    final double targetCal = summary.targetCalories ?? 2000;
    final double targetProtein = (targetCal * 0.30) / 4;
    final double targetFat = (targetCal * 0.25) / 9;
    final double targetCarb = (targetCal * 0.45) / 4;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMacroRow("Chất đạm (Protein)", currentProtein, targetProtein, Colors.blue),
            const SizedBox(height: 12),
            _buildMacroRow("Chất béo (Fat)", currentFat, targetFat, Colors.orange),
            const SizedBox(height: 12),
            _buildMacroRow("Carbs (Tinh bột)", currentCarb, targetCarb, Colors.purple),
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
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label, 
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              "${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g", 
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearPercentIndicator(
          percent: percent, 
          lineHeight: 16, 
          progressColor: color.shade600, 
          backgroundColor: color.shade100, 
          barRadius: const Radius.circular(8),
          animation: true,
          animateFromLastPercent: true,
        ),
      ],
    );
  }
}

// Scale Animation Widget for Micro-interactions
class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleOnTap({
    required this.child,
    required this.onTap,
  });

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}