import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../domain/entities/update_profile_dto.dart';
import '../../../models/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  String? _activityLevel;

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetWeightController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  void dispose() {
    // Hủy controller để tránh rò rỉ bộ nhớ
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return; // Nếu form không hợp lệ, không làm gì cả
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    // Tạo DTO để gửi lên backend
    final dto = UpdateProfileDto(
      heightCm: double.tryParse(_heightController.text),
      weightKg: double.tryParse(_weightController.text),
      targetWeightKg: double.tryParse(_targetWeightController.text),
      activityLevel: _activityLevel,
    );

    final success = await profileProvider.saveProfile(dto);

    if (mounted) {
      if (success) {
        // Kích hoạt ML xong, làm mới Dashboard
        Provider.of<DashboardProvider>(context, listen: false).fetchSummary();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Quay lại Dashboard
      } else {
        // Hiển thị lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${profileProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cập nhật Controller khi dữ liệu tải xong
  void _populateControllers(ProfileModel profile) {
    _heightController.text = profile.heightCm?.toString() ?? '';
    _weightController.text = profile.weightKg?.toString() ?? '';
    _targetWeightController.text = profile.targetWeightKg?.toString() ?? '';
    _activityLevel = profile.activityLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        actions: [
          // Nút Lưu
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _onSave,
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          // A. TRẠNG THÁI LOADING
          if (provider.status == ProfileStatus.loading && _isInit) {
            return const Center(child: CircularProgressIndicator());
          }

          // B. TRẠNG THÁI LỖI
          if (provider.status == ProfileStatus.error && _isInit) {
            return Center(child: Text('Lỗi tải hồ sơ: ${provider.errorMessage}'));
          }

          // C. TRẠNG THÁI THÀNH CÔNG
          // (Lấy dữ liệu và điền vào form 1 LẦN DUY NHẤT)
          if (provider.profile != null && _isInit) {
            _populateControllers(provider.profile!);
            _isInit = false; // Đánh dấu đã tải xong
          }
          
          // Hiển thị Form (kể cả khi đang lưu)
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Trường Chiều cao
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Chiều cao (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                        return 'Vui lòng nhập số hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Trường Cân nặng
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Cân nặng (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                        return 'Vui lòng nhập số hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Trường Cân nặng Mục tiêu
                  TextFormField(
                    controller: _targetWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Cân nặng mục tiêu (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                        return 'Vui lòng nhập số hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Mức độ Hoạt động
                  DropdownButtonFormField<String>(
                    value: _activityLevel,
                    hint: const Text('Mức độ hoạt động'),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: ActivityLevel.values.map((level) {
                      return DropdownMenuItem<String>(
                        value: level.name, // "SEDENTARY"
                        child: Text(_activityLevelToString(level)), // "Ít vận động"
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _activityLevel = value;
                      });
                    },
                  ),
                  
                  // Hiển thị vòng xoay nếu đang LƯU
                  if (provider.status == ProfileStatus.loading && !_isInit)
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0),
                      child: CircularProgressIndicator(),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Hàm trợ giúp để hiển thị tên tiếng Việt cho Enum
  String _activityLevelToString(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.SEDENTARY:
        return 'Ít vận động (văn phòng)';
      case ActivityLevel.LIGHT:
        return 'Vận động nhẹ (1-3 ngày/tuần)';
      case ActivityLevel.MODERATE:
        return 'Vận động vừa (3-5 ngày/tuần)';
      case ActivityLevel.ACTIVE:
        return 'Năng động (6-7 ngày/tuần)';
      case ActivityLevel.VERY_ACTIVE:
        return 'Rất năng động (lao động nặng)';
    }
  }
}