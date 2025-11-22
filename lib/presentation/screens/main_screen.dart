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

  // Danh sách các màn hình tương ứng với các Tab
  // (Chúng ta dùng IndexedStack để giữ trạng thái khi chuyển tab)
  final List<Widget> _screens = [
    const DashboardScreen(),   // Index 0
    const FoodSearchScreen(),  // Index 1
    const ProfileScreen(),     // Index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giữ cho các màn hình không bị load lại khi chuyển tab
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // Thanh điều hướng chuẩn Material 3
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Tìm món',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}