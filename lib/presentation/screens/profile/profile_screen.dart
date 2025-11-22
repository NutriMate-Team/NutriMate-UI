import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart'; 
import '../../../domain/entities/update_profile_dto.dart';
import '../../../models/profile_model.dart';
import '../../widgets/weight_chart.dart'; 

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

  // Điền dữ liệu an toàn
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final provider = Provider.of<ProfileProvider>(context);
      if (provider.status == ProfileStatus.success && provider.profile != null) {
        _populateControllers(provider.profile!);
        _isInit = false; 
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    final dto = UpdateProfileDto(
      heightCm: double.tryParse(_heightController.text),
      weightKg: double.tryParse(_weightController.text),
      targetWeightKg: double.tryParse(_targetWeightController.text),
      activityLevel: _activityLevel,
    );

    final success = await profileProvider.saveProfile(dto);

    if (mounted) {
      if (success) {
        Provider.of<DashboardProvider>(context, listen: false).fetchSummary();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Không pop() để tránh màn hình đen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${profileProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateControllers(ProfileModel profile) {
    _heightController.text = profile.heightCm?.toString() ?? '';
    _weightController.text = profile.weightKg?.toString() ?? '';
    _targetWeightController.text = profile.targetWeightKg?.toString() ?? '';
    
    if (profile.activityLevel != null) {
       _activityLevel = profile.activityLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _onSave,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.status == ProfileStatus.loading && _isInit) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == ProfileStatus.error && _isInit) {
            return Center(child: Text('Lỗi tải hồ sơ: ${provider.errorMessage}'));
          }
          
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Căn trái tiêu đề
                children: [
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

                  DropdownButtonFormField<String>(
                    value: _activityLevel,
                    hint: const Text('Mức độ hoạt động'),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: ActivityLevel.values.map((level) {
                      return DropdownMenuItem<String>(
                        value: level.name,
                        child: Text(_activityLevelToString(level)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _activityLevel = value;
                      });
                    },
                  ),
                  
                  // 2. THÊM BIỂU ĐỒ VÀO ĐÂY
                  const SizedBox(height: 32),
                  // Hiển thị biểu đồ với animation
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: const WeightChart(),
                  ),
                  const SizedBox(height: 32),

                  if (provider.status == ProfileStatus.loading && !_isInit)
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _activityLevelToString(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.SEDENTARY: return 'Ít vận động (văn phòng)';
      case ActivityLevel.LIGHT: return 'Vận động nhẹ (1-3 ngày/tuần)';
      case ActivityLevel.MODERATE: return 'Vận động vừa (3-5 ngày/tuần)';
      case ActivityLevel.ACTIVE: return 'Năng động (6-7 ngày/tuần)';
      case ActivityLevel.VERY_ACTIVE: return 'Rất năng động (lao động nặng)';
    }
  }
}