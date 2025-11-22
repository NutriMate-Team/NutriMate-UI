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
      appBar: AppBar(
        title: const Text(
          'Tổng quan hôm nay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                    Hero(
                      tag: 'meal_diary_button',
                      child: Material(
                        color: Colors.transparent,
                        child: SizedBox(
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
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
      shadowColor: Colors.cyan.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.water_drop, color: Colors.cyan.shade600, size: 28),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.cyan.shade400, Colors.cyan.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$currentMl / $targetMl ml", 
                    style: GoogleFonts.poppins(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Glass filling effect with visual representation
            Row(
              children: [
                // Visual glass representation
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        height: 140,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade50,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: Colors.cyan.shade300, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Water fill with animation
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                              height: 140 * percent,
                              width: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.cyan.shade300,
                                    Colors.cyan.shade600,
                                    Colors.cyan.shade700,
                                  ],
                                  stops: const [0.0, 0.7, 1.0],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(32),
                                  bottomRight: Radius.circular(32),
                                ),
                              ),
                            ),
                            // Water level indicator
                            if (percent > 0)
                              Positioned(
                                bottom: 140 * percent - 2,
                                child: Container(
                                  width: 64,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.shade900,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$glasses / $target cốc",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Progress bar and controls
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      LinearPercentIndicator(
                        lineHeight: 28.0,
                        percent: percent,
                        backgroundColor: Colors.cyan.shade50,
                        progressColor: Colors.cyan.shade600,
                        barRadius: const Radius.circular(14),
                        animation: true,
                        animateFromLastPercent: true,
                        center: Text(
                          "${(percent * 100).toStringAsFixed(0)}%", 
                          style: GoogleFonts.poppins(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold,
                            color: percent > 0.5 ? Colors.white : Colors.cyan.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quick water buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickWaterButton(
                            label: '250ml',
                            onTap: () => provider.updateWater(1),
                            color: Colors.cyan,
                          ),
                          _buildQuickWaterButton(
                            label: '500ml',
                            onTap: () => provider.updateWater(2),
                            color: Colors.cyan,
                            isLarge: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Add/Remove buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCircleButton(
                            icon: Icons.remove,
                            onTap: () => provider.updateWater(-1),
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 20), 
                          _buildCircleButton(
                            icon: Icons.add,
                            onTap: () => provider.updateWater(1),
                            color: Colors.cyan,
                            isLarge: true, 
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickWaterButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isLarge = false,
  }) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isLarge ? 13 : 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap, required Color color, bool isLarge = false}) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 14 : 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15), 
          border: Border.all(color: color, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
      shadowColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearPercentIndicator(
          percent: percent, 
          lineHeight: 12, 
          progressColor: color, 
          backgroundColor: color.shade100, 
          barRadius: const Radius.circular(6),
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