import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

enum MacroType { protein, fat, carbs }

class MacroDetailScreen extends StatefulWidget {
  final MacroType macroType;
  final double consumed;
  final double target;
  final double targetCalories;

  const MacroDetailScreen({
    super.key,
    required this.macroType,
    required this.consumed,
    required this.target,
    required this.targetCalories,
  });

  @override
  State<MacroDetailScreen> createState() => _MacroDetailScreenState();
}

class _MacroDetailScreenState extends State<MacroDetailScreen> {
  late double _customTarget;
  late TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _customTarget = widget.target;
    _targetController = TextEditingController(text: widget.target.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  String get _macroName {
    switch (widget.macroType) {
      case MacroType.protein:
        return 'Protein';
      case MacroType.fat:
        return 'Fat';
      case MacroType.carbs:
        return 'Carbohydrates';
    }
  }

  String get _macroNameVietnamese {
    switch (widget.macroType) {
      case MacroType.protein:
        return 'Chất đạm (Protein)';
      case MacroType.fat:
        return 'Chất béo (Fat)';
      case MacroType.carbs:
        return 'Carbohydrate (Carbs)';
    }
  }

  MaterialColor get _macroColor {
    switch (widget.macroType) {
      case MacroType.protein:
        return Colors.teal;
      case MacroType.fat:
        return Colors.orange;
      case MacroType.carbs:
        return Colors.purple;
    }
  }

  String get _macroDescription {
    switch (widget.macroType) {
      case MacroType.protein:
        return 'Protein rất cần thiết cho việc xây dựng và phục hồi các mô, tạo ra enzyme và hormone, cũng như hỗ trợ chức năng miễn dịch. Hãy đặt mục tiêu 0.8-1.2g mỗi kg trọng lượng cơ thể.';
      case MacroType.fat:
        return 'Chất béo trong chế độ ăn cung cấp năng lượng, hỗ trợ phát triển tế bào, bảo vệ các cơ quan, và giúp cơ thể hấp thụ các vitamin nhất định. Chất béo lành mạnh rất quan trọng cho chức năng não.';
      case MacroType.carbs:
        return 'Carbohydrate là nguồn năng lượng chính của cơ thể. Chúng cung cấp nhiên liệu cho não, cơ bắp và các hoạt động hàng ngày. Hãy chọn carbohydrate phức hợp để có năng lượng bền vững.';
    }
  }

  String get _macroBenefits {
    switch (widget.macroType) {
      case MacroType.protein:
        return '• Xây dựng và phục hồi mô cơ\n• Hỗ trợ hệ thống miễn dịch\n• Giúp no lâu và quản lý cân nặng\n• Cần thiết cho việc sản xuất enzyme và hormone';
      case MacroType.fat:
        return '• Cung cấp axit béo thiết yếu\n• Hỗ trợ sức khỏe não và chức năng nhận thức\n• Giúp hấp thụ các vitamin tan trong chất béo (A, D, E, K)\n• Duy trì làn da và mái tóc khỏe mạnh';
      case MacroType.carbs:
        return '• Nguồn năng lượng chính cho cơ thể\n• Cung cấp năng lượng cho chức năng não và sự minh mẫn\n• Hỗ trợ hiệu suất thể chất và phục hồi\n• Cung cấp chất xơ cho sức khỏe tiêu hóa';
    }
  }

  double get _caloriesPerGram {
    switch (widget.macroType) {
      case MacroType.protein:
        return 4.0;
      case MacroType.fat:
        return 9.0;
      case MacroType.carbs:
        return 4.0;
    }
  }

  double get _percentageOfCalories {
    final caloriesFromMacro = widget.consumed * _caloriesPerGram;
    return (caloriesFromMacro / widget.targetCalories) * 100;
  }

  void _updateTarget() {
    final newTarget = double.tryParse(_targetController.text);
    if (newTarget != null && newTarget > 0) {
      setState(() {
        _customTarget = newTarget;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật mục tiêu ${_macroName} thành ${newTarget.toStringAsFixed(0)}g'),
          backgroundColor: _macroColor.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.consumed / _customTarget).clamp(0.0, 1.0);
    final remaining = (_customTarget - widget.consumed).clamp(0.0, double.infinity);
    final caloriesFromMacro = widget.consumed * _caloriesPerGram;
    final targetCaloriesFromMacro = _customTarget * _caloriesPerGram;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _macroNameVietnamese,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Circular Progress
                    CircularPercentIndicator(
                      radius: 100.0,
                      lineWidth: 16.0,
                      percent: percent,
                      animation: true,
                      animateFromLastPercent: true,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(percent * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _macroColor.shade700,
                            ),
                          ),
                          Text(
                            'Hoàn thành',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      progressColor: _macroColor.shade600,
                      backgroundColor: _macroColor.shade100,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(height: 24),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Đã ăn',
                          '${widget.consumed.toStringAsFixed(0)}g',
                          _macroColor,
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatColumn(
                          'Mục tiêu',
                          '${_customTarget.toStringAsFixed(0)}g',
                          Colors.grey.shade700,
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatColumn(
                          'Còn lại',
                          '${remaining.toStringAsFixed(0)}g',
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Calories from Macro
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calories từ $_macroName',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${caloriesFromMacro.toStringAsFixed(0)} / ${targetCaloriesFromMacro.toStringAsFixed(0)} kcal',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _macroColor.shade700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _macroColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_percentageOfCalories.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _macroColor.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _macroColor.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Về $_macroName',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _macroDescription,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Benefits Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_outline,
                          color: _macroColor.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lợi ích sức khỏe',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _macroBenefits,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Goal Adjustment Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.track_changes,
                          color: _macroColor.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Điều chỉnh mục tiêu',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Mục tiêu (gram)',
                        hintText: 'Nhập số gram',
                        prefixIcon: Icon(
                          Icons.straighten,
                          color: _macroColor.shade700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _macroColor.shade700,
                            width: 2,
                          ),
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateTarget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _macroColor.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cập nhật mục tiêu',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

