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
  final List<String> _quickMealTypes = const [
    'Bữa sáng',
    'Bữa trưa',
    'Bữa tối',
    'Ăn nhẹ',
  ];
  final List<String> _otherMealTypes = const [
    'Trước tập',
    'Sau tập',
    'Đêm muộn',
  ];
  String _mealType = 'Bữa sáng';
  bool _showNutritionDetails = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '100';
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 1. Lấy Provider (listen: false vì đang ở trong hàm)
    final mealLogProvider = Provider.of<MealLogProvider>(context, listen: false);

    // 2. Tạo DTO
    // === CẬP NHẬT QUAN TRỌNG: Thêm thông tin dinh dưỡng để gửi cho Backend ===
    final dto = CreateMealLogDto(
      foodId: widget.food.id,
      quantity: double.parse(_quantityController.text),
      mealType: _mealType,
      
      // 👉 Các trường bổ sung bắt buộc cho logic tự động tạo món từ USDA
      source: widget.food.source,      // Backend cần biết nguồn (usda/local)
      name: widget.food.name,          // Backend cần tên để tạo món mới
      calories: widget.food.calories,  // Backend cần calo gốc (trên 100g)
      
      // Các chất dinh dưỡng khác (Optional nhưng nên có)
      protein: widget.food.protein,
      fat: widget.food.fat,
      carbs: widget.food.carbs,
    );
    // ========================================================================

    // 3. Gọi API
    final success = await mealLogProvider.saveLog(dto);
    
    // 4. Xử lý kết quả
    if (mounted) {
      if (success) {
        // 5. Làm mới Dashboard - AWAIT để đảm bảo dữ liệu được tải xong trước khi navigate
        final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
        await dashboardProvider.fetchSummary();
        
        // 6. Đóng 2 màn hình (AddLog và Search) để quay về Dashboard
        // Dashboard sẽ tự động cập nhật vì đã gọi fetchSummary() ở trên
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
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
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.food.calories?.toStringAsFixed(0) ?? '0'} kcal / ${widget.food.unit}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildMacroSummary(),
                      const SizedBox(height: 12),
                      _buildNutritionDetailsToggle(),
                      const SizedBox(height: 24),
                      _buildQuantityInput(),
                      const SizedBox(height: 24),
                      _buildMealTypeSection(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF00BFA5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'THÊM VÀO NHẬT KÝ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroSummary() {
    Widget macroTile(String label, double? value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value?.toStringAsFixed(1) ?? '--'}g',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        macroTile('Protein', widget.food.protein, const Color(0xFF1E88E5)),
        const SizedBox(width: 10),
        macroTile('Fat', widget.food.fat, const Color(0xFFFF7043)),
        const SizedBox(width: 10),
        macroTile('Carbs', widget.food.carbs, const Color(0xFF8E24AA)),
      ],
    );
  }

  Widget _buildQuantityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khối lượng đã ăn (grams)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStepperButton(
              icon: Icons.remove,
              onTap: () => _adjustQuantity(-25),
            ),
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Nhập số gram bạn đã ăn',
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
            ),
            _buildStepperButton(
              icon: Icons.add,
              onTap: () => _adjustQuantity(25),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: const Color(0xFFE0F2F1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(icon, color: const Color(0xFF00BFA5)),
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại bữa ăn',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Row(
              children: _quickMealTypes.take(3).map((type) {
                final isSelected = _mealType == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type == _quickMealTypes.take(3).last ? 0 : 12,
                    ),
                    child: _buildMealChip(type, isSelected),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMealChip(
                    _quickMealTypes.last,
                    _mealType == _quickMealTypes.last,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMealChip(
                    'Khác',
                    !_quickMealTypes.contains(_mealType),
                    onTap: () {
                      setState(() {
                        _mealType = _otherMealTypes.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: DropdownButtonFormField<String>(
            value: _otherMealTypes.contains(_mealType) ? _mealType : null,
            decoration: const InputDecoration(
              labelText: 'Khác (tùy chọn)',
              border: OutlineInputBorder(),
            ),
            items: _otherMealTypes
                .map(
                  (label) => DropdownMenuItem(
                    value: label,
                    child: Text(label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _mealType = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  void _adjustQuantity(int delta) {
    final current = double.tryParse(_quantityController.text) ?? 0;
    final updated = (current + delta).clamp(0, 10000);
    _quantityController.text = updated.toStringAsFixed(0);
  }

  Widget _buildMealChip(String label, bool isSelected, {VoidCallback? onTap}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        if (onTap != null) {
          onTap();
        } else {
          setState(() => _mealType = label);
        }
      },
      selectedColor: const Color(0xFF00BFA5).withOpacity(0.18),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00796B) : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildNutritionDetailsToggle() {
    final groups = _buildNutritionGroups();
    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showNutritionDetails = !_showNutritionDetails;
            });
          },
          icon: Icon(
            _showNutritionDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
          label: const Text(
            'Xem Chi tiết Dinh dưỡng',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: const Color(0xFF00796B),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...groups.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${item.value!.toStringAsFixed(1)} ${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'Giá trị tính theo khẩu phần 100g',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _showNutritionDetails
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Map<String, List<_NutritionItem>> _buildNutritionGroups() {
    final supplementGroup = [
      _NutritionItem('Chất xơ', widget.food.fiber, 'g'),
      _NutritionItem('Đường', widget.food.sugar, 'g'),
      _NutritionItem('Cholesterol', widget.food.cholesterol, 'mg'),
      _NutritionItem('Natri', widget.food.sodium, 'mg'),
    ].where((item) => item.value != null && item.value! > 0).toList();

    final vitaminGroup = [
      _NutritionItem('Vitamin A', widget.food.vitaminA, 'µg'),
      _NutritionItem('Vitamin B6', widget.food.vitaminB6, 'mg'),
      _NutritionItem('Vitamin B12', widget.food.vitaminB12, 'µg'),
      _NutritionItem('Vitamin C', widget.food.vitaminC, 'mg'),
      _NutritionItem('Vitamin D', widget.food.vitaminD, 'µg'),
      _NutritionItem('Vitamin E', widget.food.vitaminE, 'mg'),
      _NutritionItem('Vitamin K', widget.food.vitaminK, 'µg'),
    ].where((item) => item.value != null && item.value! > 0).toList();

    final mineralGroup = [
      _NutritionItem('Canxi', widget.food.calcium, 'mg'),
      _NutritionItem('Sắt', widget.food.iron, 'mg'),
      _NutritionItem('Kali', widget.food.potassium, 'mg'),
      _NutritionItem('Magie', widget.food.magnesium, 'mg'),
    ].where((item) => item.value != null && item.value! > 0).toList();

    final groups = <String, List<_NutritionItem>>{};
    if (supplementGroup.isNotEmpty) {
      groups['Nhóm bổ sung'] = supplementGroup;
    }
    if (vitaminGroup.isNotEmpty) {
      groups['Nhóm vitamin'] = vitaminGroup;
    }
    if (mineralGroup.isNotEmpty) {
      groups['Nhóm khoáng chất'] = mineralGroup;
    }

    return groups;
  }
}

class _NutritionItem {
  final String label;
  final double? value;
  final String unit;

  _NutritionItem(this.label, this.value, this.unit);
}