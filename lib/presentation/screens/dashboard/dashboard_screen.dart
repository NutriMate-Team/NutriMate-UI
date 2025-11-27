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
    // Deeper, more noticeable pale green color for background
    const Color paleMintTop = Color(0xFFE0F5E8);
    
    return Scaffold(
      backgroundColor: paleMintTop,
      appBar: AppBar(
        title: Text(
          'Tổng quan hôm nay',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: paleMintTop,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 0,
        titleSpacing: 16,
        actions: [
          // Streak Indicator - Fire icon with number
          _buildStreakIndicator(context),
          const SizedBox(width: 8),
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return IconButton(
                icon: _buildProfileAvatar(profileProvider.profile),
                tooltip: 'Hồ sơ',
            onPressed: () {
                  // Navigate to profile or show menu
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: const Color(0xFFE0F5E8), // Deeper pale green background
        child: Consumer<DashboardProvider>(
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
                controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                    // --- CALORIE STATISTICS ROW ---
                    _buildCalorieStatsRow(context, target, consumed, summary.caloriesBurned),
                    const SizedBox(height: 24),
                    // --- BIỂU ĐỒ TRÒN VỚI FIRE ICON (HERO SECTION) ---
                    _buildCalorieProgressIndicator(remaining, percent, consumed, target, summary.caloriesBurned),
                  
                  const SizedBox(height: 24),
                  
                    // --- QUICK ADD SECTION ---
                    _buildQuickAddSection(context),
                  
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
      ),
    );
  }

  // --- CÁC WIDGET CON ---

  // Calorie Statistics Row - Prominent display below title
  Widget _buildCalorieStatsRow(BuildContext context, double target, double consumed, double burned) {
    final double remaining = target - consumed;
    final bool isOverconsumption = remaining < 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActivityLogPage(),
                  ),
                );
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
  Widget _buildCalorieProgressIndicator(double remaining, double percent, double consumed, double target, double burned) {
    // Determine warning states
    final bool isOverconsumption = remaining < 0;
    final bool isNearGoal = remaining >= 0 && remaining < 200;
    
    // Dynamic colors based on warning states
    Color ringColor;
    Color backgroundColor;
    Color flameColor;
    Color remainingTextColor;
    
    if (isOverconsumption) {
      // Overconsumption: Red
      ringColor = Colors.red.shade600;
      backgroundColor = Colors.red.shade50;
      flameColor = Colors.red.shade600;
      remainingTextColor = Colors.red.shade700;
    } else if (isNearGoal) {
      // Near goal warning: Yellow/Orange
      ringColor = Colors.orange.shade500;
      backgroundColor = Colors.orange.shade50;
      flameColor = Colors.orange.shade600;
      remainingTextColor = Colors.orange.shade700;
    } else {
      // Normal: Forest Green (with dynamic flame based on progress)
      ringColor = const Color(0xFF2E7D32); // Rich forest green
      backgroundColor = Colors.green.shade50;
      flameColor = percent < 0.5 
          ? Colors.orange.shade600 
          : percent < 0.8 
              ? Colors.deepOrange.shade600 
              : Colors.red.shade600;
      remainingTextColor = const Color(0xFF1B5E20); // Darker forest green for text
    }
    
    return Hero(
      tag: 'calorie_progress',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
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
                  progressColor: ringColor, 
                  backgroundColor: backgroundColor, 
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
          ],
          ),
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
        width: 80, // Fixed width for all buttons
        height: 110, // Fixed height to accommodate icon, label, and status
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
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
                  borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
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
      child: Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
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
          borderRadius: BorderRadius.circular(30),
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

    // Tính toán MỤC TIÊU dựa trên Calo (Công thức giả định: 30% P - 25% F - 45% C)
    final double targetCal = summary.targetCalories ?? 2000;
    final double defaultProteinTarget = (targetCal * 0.30) / 4;
    final double defaultFatTarget = (targetCal * 0.25) / 9;
    final double defaultCarbTarget = (targetCal * 0.45) / 4;

    final double targetProtein = _customProteinTarget ?? defaultProteinTarget;
    final double targetFat = _customFatTarget ?? defaultFatTarget;
    final double targetCarb = _customCarbTarget ?? defaultCarbTarget;

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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
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

  // Profile Avatar with personalization
  Widget _buildProfileAvatar(dynamic profile) {
    // Check if profile has an avatar image URL (extensible for future implementation)
    // If ProfileModel is extended with avatarUrl in the future, use it here
    // String? avatarUrl = profile?.avatarUrl;
    // For now, we'll always show the colored silhouette

    // Generate a consistent color based on userId or use default
    MaterialColor avatarColor;
    if (profile != null && profile.userId != null) {
      // Generate a color from userId hash for consistency
      final hash = profile.userId.hashCode;
      final colors = [
        Colors.green,
        Colors.blue,
        Colors.purple,
        Colors.orange,
        Colors.teal,
        Colors.indigo,
        Colors.pink,
        Colors.amber,
      ];
      avatarColor = colors[hash.abs() % colors.length];
    } else {
      avatarColor = Colors.green;
    }

    // Show colored silhouette with gradient
    return CircleAvatar(
      radius: 20,
      backgroundColor: avatarColor,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              avatarColor.shade400,
              avatarColor.shade700,
            ],
          ),
        ),
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
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