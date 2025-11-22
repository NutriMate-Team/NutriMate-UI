import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _onIntroEnd(BuildContext context) async {
    // Lưu trạng thái đã xem Intro
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (context.mounted) {
      // Chuyển sang màn hình Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      autoScrollDuration: 4000, // Tự động chuyển trang sau 4s
      
      pages: [
        PageViewModel(
          title: "Theo dõi Dinh dưỡng",
          body: "Ghi lại bữa ăn hàng ngày và kiểm soát lượng calo nạp vào một cách khoa học.",
          image: _buildImage(Icons.restaurant_menu, Colors.orange),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Quét Mã Vạch",
          body: "Tìm kiếm thông tin sản phẩm siêu tốc chỉ với camera điện thoại.",
          image: _buildImage(Icons.qr_code_scanner, Colors.blue),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Sống Khỏe Mỗi Ngày",
          body: "Theo dõi tập luyện và nhận gợi ý cá nhân hóa từ AI.",
          image: _buildImage(Icons.fitness_center, Colors.green),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), 
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      
      // Các nút điều khiển
      skip: const Text('Bỏ qua', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Bắt đầu', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
      
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }

  // Hàm tạo ảnh minh họa (dùng Icon cho nhanh)
  Widget _buildImage(IconData icon, Color color) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 100, color: color),
      ),
    );
  }
}