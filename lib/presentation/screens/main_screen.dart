// file: lib/presentation/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'food_search/food_search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(), // Index 0
    const ProfileScreen(),   // Index 1
  ];

  void _onAddPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FoodSearchScreen(),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // ❌ ĐÃ XÓA FloatingActionButton (để không bị nổi lên)

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10, // Tạo bóng cho thanh điều hướng
        padding: EdgeInsets.zero, // Xóa padding mặc định để căn chỉnh tốt hơn
        child: SizedBox(
          height: 70, // Chiều cao thanh điều hướng
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Căn đều 3 phần tử
            children: [
              // --- TAB 1: TỔNG QUAN ---
              _buildTabItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Tổng quan',
                index: 0,
              ),
              
              // --- NÚT CỘNG (NẰM GIỮA & NGANG HÀNG) ---
              _buildMiddleButton(),

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

  // Widget nút giữa (Hình tròn xanh)
  Widget _buildMiddleButton() {
    return InkWell(
      onTap: _onAddPressed,
      borderRadius: BorderRadius.circular(50), // Hiệu ứng ripple tròn
      child: Container(
        width: 50, 
        height: 50,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
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