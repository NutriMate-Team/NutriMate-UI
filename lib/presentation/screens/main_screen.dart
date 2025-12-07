// file: lib/presentation/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutri_mate_ui/config/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'food_search/food_search_screen.dart';
import 'workout/workout_screen.dart';
import 'activity/activity_log_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isSpeedDialOpen = false;
  late AnimationController _speedDialController;
  late Animation<double> _speedDialAnimation;

  final List<Widget> _screens = [
    const DashboardScreen(), // Index 0
    const ProfileScreen(),   // Index 1
  ];

  @override
  void initState() {
    super.initState();
    _speedDialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _speedDialAnimation = CurvedAnimation(
      parent: _speedDialController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _speedDialController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    if (!_isSpeedDialOpen) {
      setState(() {
        _isSpeedDialOpen = true;
      });
      _speedDialController.forward();
    }
  }

  void _closeSpeedDial() {
    if (_isSpeedDialOpen) {
      // Animate close with smooth cancel animation
      _speedDialController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isSpeedDialOpen = false;
          });
        }
      });
    }
  }

  void _onAddMeal() {
    _closeSpeedDial();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FoodSearchScreen(),
      ),
    );
  }

  void _onAddWater() {
    _closeSpeedDial();
    // Navigate to dashboard and show water section
    setState(() {
      _currentIndex = 0;
    });
    // Show a snackbar to guide user to water section
    Future.delayed(const Duration(milliseconds: 300), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vuốt xuống để xem phần nước uống'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _onAddActivity() {
    _closeSpeedDial();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorkoutScreen(),
      ),
    );
  }

  void _onViewActivityLog() {
    _closeSpeedDial();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivityLogPage(),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (_isSpeedDialOpen) {
      _closeSpeedDial();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Speed Dial Overlay
          if (_isSpeedDialOpen) _buildSpeedDialOverlay(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // --- TAB 1: TỔNG QUAN ---
              _buildTabItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Tổng quan',
                index: 0,
              ),
              
              // --- PROMINENT FAB (NẰM GIỮA & NGANG HÀNG) ---
              _buildProminentFAB(),

              // --- TAB 2: HỒ SƠ ---
              _buildTabItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Hồ sơ',
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Prominent Floating Action Button
  Widget _buildProminentFAB() {
    return AnimatedRotation(
      turns: _isSpeedDialOpen ? 0.125 : 0.0, // 45 degrees (1/8 turn) when open
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
          boxShadow: HumanizeUI.heroSoftElevation(
            baseColor: HumanizeUI.paleMintTop,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Haptic feedback for satisfying interaction
              HapticFeedback.lightImpact();
              // When speed dial is open, explicitly close it (cancel action)
              // When closed, open it
              if (_isSpeedDialOpen) {
                _closeSpeedDial();
              } else {
                _toggleSpeedDial();
              }
            },
            borderRadius: BorderRadius.circular(32),
            child: Icon(
              _isSpeedDialOpen ? Icons.close : Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  // Speed Dial Overlay
  Widget _buildSpeedDialOverlay() {
    return GestureDetector(
      onTap: _closeSpeedDial, // Explicitly close on tap outside (cancel action)
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(),
              // Speed Dial Options - Prevent tap from propagating to overlay
              GestureDetector(
                onTap: () {}, // Prevent tap from closing when tapping options area
                child: FadeTransition(
                  opacity: _speedDialAnimation,
                  child: ScaleTransition(
                    scale: _speedDialAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSpeedDialOption(
                          icon: Icons.restaurant,
                          label: 'Thêm Bữa ăn',
                          color: Colors.blue,
                          onTap: _onAddMeal,
                          delay: 0,
                        ),
                        const SizedBox(height: 16),
                        _buildSpeedDialOption(
                          icon: Icons.water_drop,
                          label: 'Thêm Nước',
                          color: Colors.cyan,
                          onTap: _onAddWater,
                          delay: 50,
                        ),
                        const SizedBox(height: 16),
                        _buildSpeedDialOption(
                          icon: Icons.fitness_center,
                          label: 'Thêm Hoạt động',
                          color: Colors.orange,
                          onTap: _onAddActivity,
                          delay: 100,
                        ),
                        const SizedBox(height: 16),
                        _buildSpeedDialOption(
                          icon: Icons.history,
                          label: 'Xem Nhật ký Hoạt động',
                          color: Colors.deepPurple,
                          onTap: _onViewActivityLog,
                          delay: 150,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              // Spacer to position above bottom nav
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDialOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _speedDialController,
          curve: Interval(
            delay / 300.0,
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: FadeTransition(
        opacity: _speedDialAnimation,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: HumanizeUI.asymmetricRadius20,
              boxShadow: HumanizeUI.softElevation(baseColor: Colors.white),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: HumanizeUI.asymmetricRadius16,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.green : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}