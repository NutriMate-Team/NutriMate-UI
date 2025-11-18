import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/food_model.dart';
import '../../providers/meal_log_provider.dart'; 
import '../../providers/dashboard_provider.dart';
import '../../../domain/entities/create_meal_log_dto.dart';

class AddMealLogScreen extends StatefulWidget {
  final FoodModel food;
  const AddMealLogScreen({super.key, required this.food});

  @override
  State<AddMealLogScreen> createState() => _AddMealLogScreenState();
}

class _AddMealLogScreenState extends State<AddMealLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  String _mealType = 'Bữa sáng';

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 1. Lấy Provider (listen: false vì đang ở trong hàm)
    final mealLogProvider = Provider.of<MealLogProvider>(context, listen: false);

    // 2. Tạo DTO
    final dto = CreateMealLogDto(
      foodId: widget.food.id,
      quantity: double.parse(_quantityController.text),
      mealType: _mealType,
    );

    // 3. Gọi API
    final success = await mealLogProvider.saveLog(dto);
    
    // 4. Xử lý kết quả
    if (mounted) {
      if (success) {
        // 5. Làm mới Dashboard 
        Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
        
        // 6. Đóng 2 màn hình (AddLog và Search) để quay về Dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // 7. Hiển thị lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${mealLogProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 8. Lắng nghe trạng thái loading
    final isLoading = context.watch<MealLogProvider>().status == MealLogStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.food.name),
        actions: [
          // 9. Hiển thị vòng xoay nếu đang lưu
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _onSave,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.food.calories?.toStringAsFixed(0) ?? 'N/A'} kcal / ${widget.food.unit}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng (ví dụ: 100g, 200g...)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Vui lòng nhập một số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _mealType,
                decoration: const InputDecoration(
                  labelText: 'Loại bữa ăn',
                  border: OutlineInputBorder(),
                ),
                items: ['Bữa sáng', 'Bữa trưa', 'Bữa tối', 'Ăn nhẹ']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _mealType = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}