import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'barcode_scanner_screen.dart';
import '../../providers/food_provider.dart';
import '../../../models/food_model.dart';
import 'add_meal_log_screen.dart'; 

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce; // Timer để 'delay' khi gõ phím

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 1. HÀM TÌM KIẾM (có delay)
  void _onSearchChanged(String query) {
    // Hủy timer cũ nếu có
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    // Đặt timer mới (500ms)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        Provider.of<FoodProvider>(context, listen: false).search(query);
      }
    });
  }

  // 2. HÀM QUÉT MÃ VẠCH
  Future<void> _scanBarcode() async {
    Navigator.of(context).push(
    MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
 }

  void _navigateToAddLog(FoodModel food) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMealLogScreen(food: food),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy provider (chỉ để đọc)
    final foodProvider = context.watch<FoodProvider>();

    return Scaffold(
      appBar: AppBar(
        // Thanh tìm kiếm
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm đồ ăn (phở, gà...)...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          // Nút quét mã vạch
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: _buildBody(foodProvider),
    );
  }

  // 4. HÀM BUILD GIAO DIỆN BODY
  Widget _buildBody(FoodProvider provider) {
    // A. Trạng thái Loading
    if (provider.status == FoodStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // B. Trạng thái Lỗi
    if (provider.status == FoodStatus.error) {
      return Center(child: Text('Lỗi: ${provider.errorMessage}'));
    }

    // C. Trạng thái Thành công (Quét Barcode)
    if (provider.status == FoodStatus.success && provider.barcodeResult != null) {
      // Hiển thị 1 kết quả duy nhất từ barcode
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _navigateToAddLog(provider.barcodeResult!);
      });
      return const Center(child: Text('Đã tìm thấy sản phẩm...'));
    }

    // D. Trạng thái Thành công (Tìm kiếm)
    if (provider.status == FoodStatus.success && provider.searchResults.isNotEmpty) {
      return ListView.builder(
        itemCount: provider.searchResults.length,
        itemBuilder: (context, index) {
          final food = provider.searchResults[index];
          return _buildFoodTile(food);
        },
      );
    }

    // E. Trạng thái Ban đầu (hoặc tìm không thấy)
    return const Center(
      child: Text('Gõ để tìm kiếm hoặc quét mã vạch'),
    );
  }

  // 5. HÀM BUILD 1 HÀNG KẾT QUẢ
  Widget _buildFoodTile(FoodModel food) {
    return ListTile(
      title: Text(food.name),
      subtitle: Text(
        '${food.calories?.toStringAsFixed(0) ?? 'N/A'} kcal / ${food.unit}',
      ),
      trailing: Text(food.source.toUpperCase()), // "USDA" hoặc "VIETNAM_NIN"
      onTap: () {
        // Khi nhấn vào 1 món
        _navigateToAddLog(food);
      },
    );
  }
}