import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/food_provider.dart';
import 'add_meal_log_screen.dart'; 

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false; // Biến để tránh quét 1 mã nhiều lần

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Hàm này được gọi khi quét thành công
  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    // Nếu đang xử lý, bỏ qua
    if (_isProcessing) return;

    // Đánh dấu là đang xử lý
    setState(() { _isProcessing = true; });

    // Chỉ lấy mã vạch đầu tiên
    final String? code = capture.barcodes.first.rawValue;
    if (code == null) {
      setState(() { _isProcessing = false; }); // Mở khóa nếu mã rỗng
      return;
    }

    // Lấy provider và gọi API
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    await foodProvider.scan(code);

    if (!mounted) return;

    // Sau khi gọi API, kiểm tra kết quả
    if (foodProvider.status == FoodStatus.success && foodProvider.barcodeResult != null) {
      // Thành công: ĐI LUÔN sang màn hình AddMealLog
      Navigator.of(context).pushReplacement( // Dùng Replacement
        MaterialPageRoute(
          builder: (context) => AddMealLogScreen(food: foodProvider.barcodeResult!),
        ),
      );
    } else {
      // Thất bại (vd: không tìm thấy)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${foodProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
      // Mở khóa để cho phép quét lại
      setState(() { _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã vạch')),
      body: Stack(
        children: [
          // Lớp Camera
          MobileScanner(
            controller: controller,
            onDetect: _onBarcodeDetected, // Gắn hàm xử lý
          ),

          // Lớp Giao diện (Overlay)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Hiển thị vòng xoay nếu đang xử lý
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}