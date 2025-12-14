import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers & Models
import '../../providers/dashboard_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/streak_provider.dart';
import '../../../models/workout_log_model.dart';
import 'package:nutri_mate_ui/config/theme.dart';

// Screens
import 'package:nutri_mate_ui/presentation/screens/workout/workout_screen.dart';
import 'package:nutri_mate_ui/presentation/screens/meal_diary/meal_diary_screen.dart';
import 'package:nutri_mate_ui/presentation/screens/food_search/food_search_screen.dart';
import 'package:nutri_mate_ui/presentation/screens/streak/streak_detail_screen.dart';
import '../activity/activity_log_page.dart';
import 'macro_detail_screen.dart' show MacroType;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _quickActionsScrollController = ScrollController();
  final GlobalKey _waterSectionKey = GlobalKey();
  double _quickActionsScrollPosition = 0.0;
  double? _customProteinTarget;
  double? _customFatTarget;
  double? _customCarbTarget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
      // Fetch profile for avatar display
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
    
    // Listen to quick actions scroll for snap and indicator
    _quickActionsScrollController.addListener(_onQuickActionsScroll);
    _loadMacroTargets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _quickActionsScrollController.dispose();
    super.dispose();
  }

  void _onQuickActionsScroll() {
    setState(() {
      _quickActionsScrollPosition = _quickActionsScrollController.offset;
    });
  }

  void _snapToNearestItem() {
    if (!_quickActionsScrollController.hasClients) return;
    
    // Button width (80) + horizontal padding (6*2) = 92 per item
    const double itemWidth = 92.0;
    const double padding = 12.0; // ListView padding
    
    final double currentOffset = _quickActionsScrollController.offset;
    final double itemIndex = (currentOffset + padding) / itemWidth;
    final int nearestIndex = itemIndex.round().clamp(0, 5); // 6 items total (0-5)
    
    final double targetOffset = (nearestIndex * itemWidth) - padding;
    
    _quickActionsScrollController.animateTo(
      targetOffset.clamp(0.0, _quickActionsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadMacroTargets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customProteinTarget = prefs.getDouble('macro_target_protein');
      _customFatTarget = prefs.getDouble('macro_target_fat');
      _customCarbTarget = prefs.getDouble('macro_target_carb');
    });
  }

  Future<void> _saveMacroTargets(double protein, double fat, double carb) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('macro_target_protein', protein);
    await prefs.setDouble('macro_target_fat', fat);
    await prefs.setDouble('macro_target_carb', carb);
    setState(() {
      _customProteinTarget = protein;
      _customFatTarget = fat;
      _customCarbTarget = carb;
    });
  }

  void _scrollToWaterSection() {
    // Wait for the next frame to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _waterSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1, // Position near top (10% from top of viewport)
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Match Profile Screen's clean background
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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 0,
        titleSpacing: 16,
        actions: [
          // Streak Indicator - Fire icon with number
          _buildStreakIndicator(context),
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
            final double burned = summary.caloriesBurned;
            
            // FIX: If no food has been consumed, the progress should be explicitly zero,
            // even if calories have been burned. This addresses the visual bug where the
            // circle is partially filled when 'Đã nạp' is 0.
            double percent;
            double netCalories;
            double remaining;
            
            if (consumed == 0) {
              // No food consumed = no progress, regardless of exercise
              percent = 0.0;
              netCalories = 0;
              remaining = target; // Full target remaining
            } else {
              // CRITICAL: Calculate net calories (consumed - burned) for accurate progress
              // Net calories = calories consumed minus calories burned from exercise
              netCalories = consumed - burned;
              
              // CRITICAL: Calculate progress percentage using NET calories, not just consumed
              // Formula: (Net Calories Consumed) / (Target Calories)
              // This ensures exercise is properly accounted for in the progress calculation
              percent = (netCalories / target);
              
              // Clamp percent to valid range (0.0 to 1.0) for drawing purposes
              // Drawing functions and color logic expect values between 0.0 and 1.0
              // Note: Over-consumption is detected via 'remaining < 0' in color logic
              // Negative net calories (high burn) -> clamp to 0%
              if (percent < 0) percent = 0.0;
              // Over-consumption (percent > 1.0) -> clamp to 100% for drawing
              // The actual excess is still visible via negative 'remaining' value
              if (percent > 1.0) percent = 1.0;
              
              // SIMPLIFIED: Use backend-calculated remainingCalories (more reliable)
              // Backend already calculates: remainingCalories = targetCalories - netCalories
              // This ensures consistency with backend logic and reduces frontend calculation errors
              remaining = summary.remainingCalories ?? (target - netCalories);
            }

            // Determine progress color based on remaining calories status
            // Goal met or exceeded (remaining <= 0) -> Gray
            // Goal not met (remaining > 0) -> Blue
            final Color progressColor = remaining <= 0 
                ? Colors.grey.shade400  // Gray when goal met/exceeded
                : Colors.blue;            // Blue when working towards goal

            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: SingleChildScrollView(
                controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                    // --- CALORIE STATISTICS ROW ---
                    _buildCalorieStatsRow(context, target, consumed, summary.caloriesBurned),
                    const SizedBox(height: 24),
                    // --- BIỂU ĐỒ TRÒN VỚI FIRE ICON (HERO SECTION) ---
                    _buildCalorieProgressIndicator(remaining, percent, consumed, target, summary.caloriesBurned, progressColor),
                  
                  const SizedBox(height: 24),
                  
                    // --- QUICK ADD SECTION ---
                    _buildQuickAddSection(context),
                  
                    const SizedBox(height: 24),

                    // --- WORKOUT LOG SECTION ---
                    _buildWorkoutLogSection(context),
                  
                    const SizedBox(height: 16),

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
                    _buildWaterTrackerCard(provider, _waterSectionKey),

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

  // Calorie Statistics Row - Prominent display below title
  Widget _buildCalorieStatsRow(BuildContext context, double target, double consumed, double burned) {
    // CRITICAL: Calculate remaining using NET calories (consumed - burned)
    // This ensures exercise calories are properly accounted for
    final double netCalories = consumed - burned;
    final double remaining = target - netCalories;
    final bool isOverconsumption = remaining < 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HumanizeUI.asymmetricRadius20,
        boxShadow: HumanizeUI.softElevation(baseColor: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildProminentStat(
              label: 'Mục tiêu',
              value: target.toStringAsFixed(0),
              color: Colors.green,
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey.shade300,
            ),
            _buildProminentStat(
              label: 'Đã nạp',
              value: consumed.toStringAsFixed(0),
              color: isOverconsumption ? Colors.red : Colors.blue,
              shouldHighlight: isOverconsumption,
              highlightColor: Colors.red.shade100,
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey.shade300,
            ),
            _buildProminentStat(
              label: 'Đã đốt',
              value: burned.toStringAsFixed(0),
              color: Colors.green,
              shouldHighlight: burned > 0,
              onTap: () async {
                // Navigate to activity log and wait for potential changes
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActivityLogPage(),
                  ),
                );
                // Re-fetch dashboard summary (including updated burned calories)
                if (context.mounted) {
                  Provider.of<DashboardProvider>(context, listen: false)
                      .fetchSummary();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProminentStat({
    required String label,
    required String value,
    required Color color,
    bool shouldHighlight = false,
    Color? highlightColor,
    VoidCallback? onTap,
  }) {
    final effectiveHighlightColor = highlightColor ?? Colors.orange.shade100;
    
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          children: [
            shouldHighlight
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: effectiveHighlightColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Circular Progress Indicator với Fire Icon - Hero Section
  Widget _buildCalorieProgressIndicator(double remaining, double percent, double consumed, double target, double burned, Color progressColor) {
    // Determine icon and text colors based on progress status
    final Color flameColor = progressColor;
    final Color remainingTextColor = remaining <= 0 
        ? Colors.grey.shade700  // Gray text when goal met/exceeded
        : const Color(0xFF1B5E20); // Dark green text when working towards goal
    
    return Hero(
      tag: 'calorie_progress',
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: HumanizeUI.asymmetricRadius24,
          boxShadow: HumanizeUI.heroSoftElevation(baseColor: Colors.white),
        ),
          padding: const EdgeInsets.all(16),
        child: Stack(
              alignment: Alignment.center,
              children: [
            // Single-color progress ring based on percent with dynamic color
            CustomPaint(
              size: const Size(280, 280),
              painter: _ProgressRingPainter(percent: percent, progressColor: progressColor),
            ),
            // Center content with fire icon
            Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                          color: remainingTextColor,
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
                    ],
                ),
              ],
        ),
      ),
    );
  }

  // Quick Add Section - Horizontal Scrollable
  Widget _buildQuickAddSection(BuildContext context) {
    // Get remaining calories for meal predictions
    final provider = Provider.of<DashboardProvider>(context);
    final summary = provider.summary;
    final double target = summary?.targetCalories ?? 2000;
    final double consumed = summary?.caloriesConsumed ?? 0;
    final double remaining = summary?.remainingCalories ?? (target - consumed);
    
    // Calculate suggested calories per meal (divide remaining by 4 meals)
    final double suggestedPerMeal = remaining > 0 ? (remaining / 4) : 0;
    
    // Calculate water status - always show target
    final String? waterStatus = 'Mục tiêu 2000ml';
    
    // Calculate activity status - always show burned calories
    final double caloriesBurned = summary?.caloriesBurned ?? 0;
    final String? activityStatus = 'Đã đốt ${caloriesBurned.toStringAsFixed(0)} Calo';
    
    final quickActions = [
      {'name': 'Bữa sáng', 'icon': Icons.wb_sunny, 'color': Colors.orange, 'isMeal': true},
      {'name': 'Bữa trưa', 'icon': Icons.lunch_dining, 'color': Colors.blue, 'isMeal': true},
      {'name': 'Bữa tối', 'icon': Icons.dinner_dining, 'color': Colors.purple, 'isMeal': true},
      {'name': 'Ăn nhẹ', 'icon': Icons.cookie, 'color': Colors.green, 'isMeal': true},
      {'name': 'Nước', 'icon': Icons.water_drop, 'color': Colors.cyan, 'isMeal': false},
      {'name': 'Luyện tập', 'icon': Icons.fitness_center, 'color': Colors.red, 'isMeal': false},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HumanizeUI.asymmetricRadius20,
        boxShadow: HumanizeUI.softElevation(baseColor: Colors.white),
      ),
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
              height: 120, // Fixed height to accommodate icon, label, and status
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    // Snap to nearest item when scrolling ends
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _snapToNearestItem();
                    });
                  }
                  return false;
                },
                child: ListView(
                  controller: _quickActionsScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(), // Smooth scrolling with bounce effect
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: quickActions.map((action) {
                    final isMeal = action['isMeal'] as bool;
                    final actionName = action['name'] as String;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildQuickAddButton(
                        context: context,
                        label: actionName,
                        icon: action['icon'] as IconData,
                        color: action['color'] as Color,
                        calorieEstimate: isMeal && suggestedPerMeal > 0 ? suggestedPerMeal : null,
                        waterStatus: actionName == 'Nước' ? waterStatus : null,
                        activityStatus: actionName == 'Luyện tập' ? activityStatus : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Scroll indicator
            _buildScrollIndicator(quickActions.length),
          ],
        ),
      ),
    );
  }

  // Workout Log Section - Display today's logged exercises
  Widget _buildWorkoutLogSection(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final workoutLogs = provider.todayWorkoutLogs;
    final isLoading = provider.isLoadingWorkoutLogs;
    final totalBurned = provider.totalCaloriesBurnedToday;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HumanizeUI.asymmetricRadius20,
        boxShadow: HumanizeUI.softElevation(baseColor: Colors.white),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center, color: Colors.orange.shade600, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Bài tập hôm nay',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.orange.shade600),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const WorkoutScreen()),
                  ).then((_) {
                    // Refresh workout logs when returning from workout screen
                    provider.refreshWorkoutLogs();
                  });
                },
                tooltip: 'Thêm bài tập',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Total calories burned summary
          if (totalBurned > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, 
                       color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng: ${totalBurned.toStringAsFixed(0)} calo',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Workout logs list
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (workoutLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center, 
                         size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có bài tập nào hôm nay',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const WorkoutScreen()),
                        ).then((_) {
                          provider.refreshWorkoutLogs();
                        });
                      },
                      icon: Icon(Icons.add, size: 18),
                      label: Text(
                        'Thêm bài tập',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workoutLogs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = workoutLogs[index];
                return _buildWorkoutLogItem(context, log, provider);
              },
            ),
        ],
      ),
    );
  }

  // Individual workout log item with delete functionality
  Widget _buildWorkoutLogItem(
    BuildContext context,
    WorkoutLogModel log,
    DashboardProvider provider,
  ) {
    final exerciseName = log.exercise?.name ?? 'Bài tập';
    final duration = log.durationMin;
    final calories = log.caloriesBurned;
    
    // Format time
    final time = log.loggedAt;
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Colors.red.shade600),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Xóa bài tập?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Bạn có chắc muốn xóa "$exerciseName"?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Hủy', style: GoogleFonts.poppins()),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Xóa', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) async {
        final success = await provider.deleteWorkoutLogEntry(log.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success 
                  ? 'Đã xóa bài tập' 
                  : 'Lỗi xóa bài tập'),
              backgroundColor: success ? Colors.green : Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Exercise icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.fitness_center,
                color: Colors.orange.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Exercise details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exerciseName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${duration.toStringAsFixed(0)} phút',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.local_fire_department, 
                           size: 14, color: Colors.orange.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${calories.toStringAsFixed(0)} calo',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time
            Text(
              timeStr,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 8),
            // Delete button (alternative to swipe)
            IconButton(
              icon: Icon(Icons.delete_outline, 
                        color: Colors.grey.shade400, size: 20),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      'Xóa bài tập?',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Bạn có chắc muốn xóa "$exerciseName"?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Hủy', style: GoogleFonts.poppins()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text('Xóa', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  final success = await provider.deleteWorkoutLogEntry(log.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                            ? 'Đã xóa bài tập' 
                            : 'Lỗi xóa bài tập'),
                        backgroundColor: success ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
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
    double? calorieEstimate,
    String? waterStatus,
    String? activityStatus,
  }) {
    return _ScaleOnTap(
      pressColor: color, // Pass color for immediate press feedback
      onTap: () {
        // Haptic feedback for satisfying interaction
        HapticFeedback.lightImpact();
        if (label == 'Luyện tập') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const WorkoutScreen()),
          );
        } else if (label == 'Nước') {
          // Scroll to water section smoothly
          _scrollToWaterSection();
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
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: HumanizeUI.asymmetricRadius16,
          border: Border.all(color: color.withOpacity(0.22), width: 1.4),
          boxShadow: HumanizeUI.softElevation(
            baseColor: Colors.white,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
                boxShadow: HumanizeUI.softElevation(
                  baseColor: Colors.white,
                ),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
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
            // Status labels: calorie estimate for meals, water status for water, activity status for exercise
            if (calorieEstimate != null) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: HumanizeUI.asymmetricRadius16,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Max ${calorieEstimate.toStringAsFixed(0)} Calo',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
            ] else if (waterStatus != null) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade100,
                  borderRadius: HumanizeUI.asymmetricRadius16,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    waterStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.cyan.shade800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
            ] else if (activityStatus != null) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: HumanizeUI.asymmetricRadius16,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    activityStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScrollIndicator(int itemCount) {
    if (!_quickActionsScrollController.hasClients) {
      return const SizedBox(height: 8);
    }
    
    // Calculate which item is currently in view
    const double itemWidth = 92.0; // Button width (80) + padding (6*2)
    const double padding = 12.0;
    final double maxScrollExtent = _quickActionsScrollController.position.maxScrollExtent;
    final double currentOffset = _quickActionsScrollPosition;
    
    // Only show indicator if there's scrollable content
    if (maxScrollExtent <= 0) {
      return const SizedBox(height: 8);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (index) {
          // Calculate if this dot should be active based on scroll position
          final double itemStart = (index * itemWidth) - padding;
          final double itemEnd = itemStart + itemWidth;
          final double viewportWidth = _quickActionsScrollController.position.viewportDimension;
          final double visibleStart = currentOffset;
          final double visibleEnd = currentOffset + viewportWidth;
          
          // Dot is active if the item is at least partially visible
          final bool isActive = itemStart < visibleEnd && itemEnd > visibleStart;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 8 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive 
                  ? Colors.blue.shade400 
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWaterTrackerCard(DashboardProvider provider, GlobalKey key) {
    int glasses = provider.waterGlasses;
    int target = 8; 
    int mlPerGlass = 250; 
    int currentMl = glasses * mlPerGlass;
    int targetMl = target * mlPerGlass;
    double percent = glasses / target;
    if (percent > 1) percent = 1;

    return Container(
      key: key,
      child: Container(
        decoration: BoxDecoration(
      color: Colors.white,
          borderRadius: HumanizeUI.asymmetricRadius20,
          boxShadow: HumanizeUI.softElevation(baseColor: Colors.white),
        ),
          padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              // Header
            Row(
              children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade50,
                      borderRadius: HumanizeUI.asymmetricRadius16,
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
            const SizedBox(height: 12),
            // Linear Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 12.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick Add buttons as rounded chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _buildWaterChipButton(
                    label: '250ml',
                  onTap: () => provider.updateWater(-1),
                    color: Colors.cyan,
                  icon: Icons.remove,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _buildWaterChipButton(
                    label: '250ml',
                  onTap: () => provider.updateWater(1),
                    color: Colors.cyan,
                  icon: Icons.add,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _buildWaterChipButton(
                    label: 'Tùy chỉnh',
                    onTap: () => _showCustomWaterDialog(context, provider),
                    color: Colors.cyan,
                    icon: Icons.edit,
                  ),
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
    IconData icon = Icons.add,
  }) {
    return _ScaleOnTap(
      onTap: () {
        // Haptic feedback for satisfying interaction
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.cyan.withOpacity(0.1),
          borderRadius: HumanizeUI.asymmetricRadius24,
          boxShadow: HumanizeUI.softElevation(baseColor: Colors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.cyan[700], size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.cyan[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomWaterDialog(BuildContext context, DashboardProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _CustomWaterDialog(
          provider: provider,
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
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

    // SỬ DỤNG MACRO TARGETS TỪ BACKEND (đã tính sẵn dựa trên mục tiêu và vận động)
    // Nếu backend chưa có, fallback về tính toán cũ
    final double targetCal = summary.targetCalories ?? 2000;
    
    double defaultProteinTarget, defaultFatTarget, defaultCarbTarget;
    
    if (summary.targetProtein != null && summary.targetFat != null && summary.targetCarbs != null) {
      // Sử dụng macro targets từ backend (đã tính đúng dựa trên mục tiêu và vận động)
      defaultProteinTarget = summary.targetProtein!;
      defaultFatTarget = summary.targetFat!;
      defaultCarbTarget = summary.targetCarbs!;
    } else {
      // Fallback: Tính toán cũ nếu backend chưa có
      // Công thức mặc định: 30% P - 25% F - 45% C
      defaultProteinTarget = (targetCal * 0.30) / 4;
      defaultFatTarget = (targetCal * 0.25) / 9;
      defaultCarbTarget = (targetCal * 0.45) / 4;
    }

    final double targetProtein = _customProteinTarget ?? defaultProteinTarget;
    final double targetFat = _customFatTarget ?? defaultFatTarget;
    final double targetCarb = _customCarbTarget ?? defaultCarbTarget;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HumanizeUI.asymmetricRadius20,
        boxShadow: HumanizeUI.softElevation(baseColor: Colors.white),
      ),
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
                    color: Colors.green.shade50,
                    borderRadius: HumanizeUI.asymmetricRadius16,
                  ),
                  child: Icon(Icons.analytics, color: Colors.green.shade600, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Thống kê Dinh dưỡng",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Chỉnh sửa mục tiêu vĩ mô',
                  onPressed: () => _showMacroTargetEditor(
                    defaultProteinTarget,
                    defaultFatTarget,
                    defaultCarbTarget,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMacroRow(
              context,
              "Chất đạm (Protein)",
              currentProtein,
              targetProtein,
              Colors.teal,
              MacroType.protein,
              defaultTargets: (
                protein: defaultProteinTarget,
                fat: defaultFatTarget,
                carb: defaultCarbTarget
              ),
            ),
            const SizedBox(height: 18),
            _buildMacroRow(
              context,
              "Chất béo (Fat)",
              currentFat,
              targetFat,
              Colors.orange,
              MacroType.fat,
              defaultTargets: (
                protein: defaultProteinTarget,
                fat: defaultFatTarget,
                carb: defaultCarbTarget
              ),
            ),
            const SizedBox(height: 18),
            _buildMacroRow(
              context,
              "Carbohydrate (Carbs)",
              currentCarb,
              targetCarb,
              Colors.purple,
              MacroType.carbs,
              defaultTargets: (
                protein: defaultProteinTarget,
                fat: defaultFatTarget,
                carb: defaultCarbTarget
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(
    BuildContext context,
    String label,
    double consumed,
    double target,
    MaterialColor color,
    MacroType macroType, {
    required ({double protein, double fat, double carb}) defaultTargets,
  }) {
    double percent = (consumed / target);
    if (percent < 0) percent = 0;
    // Don't cap percent - allow it to exceed 1.0 to detect overconsumption
    
    // Determine color based on completion status
    Color progressBarColor;
    Color textColor;
    Color indicatorColor;
    
    if (percent >= 1.2) {
      // Overconsumption warning (>= 120%)
      progressBarColor = Colors.orange.shade400;
      textColor = Colors.orange.shade700;
      indicatorColor = Colors.orange.shade600;
    } else if (percent >= 1.0) {
      // Goal met (100% - 119%)
      progressBarColor = Colors.green.shade500;
      textColor = Colors.green.shade700;
      indicatorColor = Colors.green.shade600;
    } else {
      // Normal progress (< 100%)
      progressBarColor = color.shade600;
      textColor = color.shade700;
      indicatorColor = color;
    }
    
    // Cap visual progress at 100% to prevent overflow
    double visualPercent = percent > 1.0 ? 1.0 : percent;
    
    return InkWell(
      onTap: () => _showMacroTargetEditor(
        defaultTargets.protein,
        defaultTargets.fat,
        defaultTargets.carb,
        focusMacro: macroType,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
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
                        color: indicatorColor,
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
                Row(
                  children: [
                    Text(
                      "${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: textColor,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearPercentIndicator(
              percent: visualPercent,
              lineHeight: 16,
              progressColor: progressBarColor,
              backgroundColor: color.shade100,
              barRadius: const Radius.circular(8),
              animation: true,
              animateFromLastPercent: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showMacroTargetEditor(
    double defaultProtein,
    double defaultFat,
    double defaultCarb, {
    MacroType? focusMacro,
  }) {
    final proteinController = TextEditingController(
      text: (_customProteinTarget ?? defaultProtein).toStringAsFixed(0),
    );
    final fatController = TextEditingController(
      text: (_customFatTarget ?? defaultFat).toStringAsFixed(0),
    );
    final carbController = TextEditingController(
      text: (_customCarbTarget ?? defaultCarb).toStringAsFixed(0),
    );

    final proteinFocus = FocusNode();
    final fatFocus = FocusNode();
    final carbFocus = FocusNode();

    void requestInitialFocus() {
      switch (focusMacro) {
        case MacroType.protein:
          proteinFocus.requestFocus();
          break;
        case MacroType.fat:
          fatFocus.requestFocus();
          break;
        case MacroType.carbs:
          carbFocus.requestFocus();
          break;
        default:
          proteinFocus.requestFocus();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => requestInitialFocus());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa mục tiêu dinh dưỡng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMacroTargetField(
              label: 'Protein (g)',
              controller: proteinController,
              focusNode: proteinFocus,
            ),
            const SizedBox(height: 12),
            _buildMacroTargetField(
              label: 'Fat (g)',
              controller: fatController,
              focusNode: fatFocus,
            ),
            const SizedBox(height: 12),
            _buildMacroTargetField(
              label: 'Carbs (g)',
              controller: carbController,
              focusNode: carbFocus,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final protein = double.tryParse(proteinController.text) ?? defaultProtein;
              final fat = double.tryParse(fatController.text) ?? defaultFat;
              final carb = double.tryParse(carbController.text) ?? defaultCarb;

              _saveMacroTargets(protein, fat, carb);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã cập nhật mục tiêu dinh dưỡng'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ).then((_) {
      proteinController.dispose();
      fatController.dispose();
      carbController.dispose();
      proteinFocus.dispose();
      fatFocus.dispose();
      carbFocus.dispose();
    });
  }

  Widget _buildMacroTargetField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Streak Indicator - Fire icon with streak number (Dynamic Visual)
  Widget _buildStreakIndicator(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
        final int currentStreak = streakProvider.currentStreak;
        
        // Get dynamic visual properties based on streak
        final double iconSize = _getStreakIconSize(currentStreak);
        final Color iconColor = _getStreakIconColor(currentStreak);
        final Color badgeColor = _getStreakBadgeColor(currentStreak);
        final Color borderColor = _getStreakBorderColor(currentStreak);
        final List<BoxShadow> glowShadows = _getStreakGlow(currentStreak);
        final double textSize = _getStreakTextSize(currentStreak);
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StreakDetailScreen(
                  currentStreak: currentStreak,
                  bestStreak: currentStreak > 20 ? currentStreak : 20, // Default or use current if higher
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: EdgeInsets.symmetric(
              horizontal: 12 + (currentStreak >= 14 ? 2 : 0),
              vertical: 6 + (currentStreak >= 14 ? 1 : 0),
            ),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: currentStreak >= 14 ? 2.0 : 1.5,
              ),
              boxShadow: glowShadows,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
      children: [
                Icon(
                  Icons.local_fire_department,
                  color: iconColor,
                  size: iconSize,
                ),
                const SizedBox(width: 6),
                Text(
                  '$currentStreak',
                  style: GoogleFonts.poppins(
                    fontSize: textSize,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper: Get icon size based on streak (scales at milestones)
  double _getStreakIconSize(int streak) {
    if (streak >= 30) {
      return 28.0; // Large for 30+ days
    } else if (streak >= 14) {
      return 24.0; // Medium-large for 14+ days
    } else if (streak >= 7) {
      return 22.0; // Medium for 7+ days
    } else {
      return 20.0; // Small for 1-6 days
    }
  }

  // Helper: Get icon color based on streak intensity
  Color _getStreakIconColor(int streak) {
    if (streak >= 14) {
      // Vibrant Red-Orange for high streaks
      return const Color(0xFFFF4500); // OrangeRed
    } else if (streak >= 7) {
      // Brighter Orange for medium streaks
      return Colors.orange.shade700;
    } else {
      // Soft Orange for low streaks
      return Colors.orange.shade600;
    }
  }

  // Helper: Get badge background color
  Color _getStreakBadgeColor(int streak) {
    if (streak >= 14) {
      return const Color(0xFFFF4500).withOpacity(0.2); // Vibrant red-orange with opacity
    } else if (streak >= 7) {
      return Colors.orange.shade700.withOpacity(0.18); // Brighter orange
    } else {
      return Colors.orange.shade700.withOpacity(0.15); // Soft orange
    }
  }

  // Helper: Get border color
  Color _getStreakBorderColor(int streak) {
    if (streak >= 14) {
      return const Color(0xFFFF4500); // Vibrant red-orange
    } else if (streak >= 7) {
      return Colors.orange.shade700; // Brighter orange
    } else {
      return Colors.orange.shade600; // Soft orange
    }
  }

  // Helper: Get glow/shadow effect based on streak
  List<BoxShadow> _getStreakGlow(int streak) {
    if (streak >= 14) {
      // Strong glow for high streaks
      return [
        BoxShadow(
          color: const Color(0xFFFF4500).withOpacity(0.5),
          blurRadius: 8,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: const Color(0xFFFF4500).withOpacity(0.3),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];
    } else if (streak >= 7) {
      // Subtle glow for medium streaks
      return [
        BoxShadow(
          color: Colors.orange.shade700.withOpacity(0.4),
          blurRadius: 6,
          spreadRadius: 0.5,
        ),
      ];
    } else {
      // No glow for low streaks
      return [];
    }
  }

  // Helper: Get text size (slightly larger for high streaks)
  double _getStreakTextSize(int streak) {
    if (streak >= 14) {
      return 17.0; // Slightly larger for high streaks
    } else if (streak >= 7) {
      return 16.5; // Medium size
    } else {
      return 16.0; // Standard size
    }
  }

}

// Scale Animation Widget for Micro-interactions
class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? pressColor; // Optional color for background darkening effect

  const _ScaleOnTap({
    required this.child,
    required this.onTap,
    this.pressColor,
  });

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    // Fast animation for immediate feedback (50ms to reach full effect)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
      onTapDown: (_) {
        // Immediate feedback - start animation instantly (within 100ms)
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.pressColor != null
                ? Stack(
      children: [
                      widget.child,
                      // Overlay darkening effect on press
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(_colorAnimation.value * 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  )
                : widget.child,
          );
        },
      ),
    );
  }
}

class _CustomWaterDialog extends StatefulWidget {
  final DashboardProvider provider;
  final VoidCallback onClose;

  const _CustomWaterDialog({
    required this.provider,
    required this.onClose,
  });

  @override
  State<_CustomWaterDialog> createState() => _CustomWaterDialogState();
}

class _CustomWaterDialogState extends State<_CustomWaterDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAction(bool isAdd) {
    final mlText = _controller.text.trim();
    if (mlText.isNotEmpty) {
      final ml = int.tryParse(mlText);
      if (ml != null && ml > 0) {
        widget.provider.updateWaterByMl(ml, isAdd: isAdd);
        widget.onClose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ${isAdd ? 'thêm' : 'trừ'} $ml ml nước'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.cyan[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập số hợp lệ'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.water_drop, color: Colors.cyan[700], size: 24),
          const SizedBox(width: 8),
          Text(
            'Nhập lượng nước',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Số ml',
              hintText: 'Nhập số ml (ví dụ: 500)',
              prefixIcon: Icon(Icons.water_drop, color: Colors.cyan[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan[700]!, width: 2),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 16),
            autofocus: true,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleAction(false),
                  icon: const Icon(Icons.remove, size: 18),
                  label: Text(
                    'Trừ',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.cyan[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleAction(true),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Thêm',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.cyan[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onClose,
          child: Text(
            'Hủy',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for elegant segmented circular ring
// Based on picture 2: Dark green (top left), Orange (right), Light green (bottom left)
// Single-color progress ring painter
class _ProgressRingPainter extends CustomPainter {
  final double percent;
  final Color progressColor;
  
  _ProgressRingPainter({required this.percent, required this.progressColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 140.0;
    final strokeWidth = 20.0;
    
    // Full circle (360 degrees) - complete ring without gaps
    // Flutter's drawArc: 0° = right (3 o'clock), goes counterclockwise
    // To start from top (12 o'clock), we subtract 90° (π/2)
    final startAngle = -math.pi / 2; // Start from top (12 o'clock)
    final sweepAngle = 2 * math.pi; // 360 degrees (full circle)
    
    // Calculate progress sweep angle
    final progressSweepAngle = sweepAngle * percent.clamp(0.0, 1.0);
    
    // FIX: Always draw full background ring first to ensure seamless base
    // This provides the complete track as a foundation
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );
    
    // Draw progress ring on top of background (filled portion)
    // This ensures perfect alignment and seamless overlay
    if (percent > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round; // Round caps for smooth appearance
      
      // Draw progress arc from start, overlaying the background
      // The progress paint will completely cover the background where it overlaps
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweepAngle,
        false,
        progressPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.progressColor != progressColor;
  }
}

