import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _goalStartDateController;
  String? _activityLevel;
  String? _avatarPath; // For storing avatar image path
  DateTime? _goalStartDate;
  double? _weeklyGoalRate;

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetWeightController = TextEditingController();
    _goalStartDateController = TextEditingController();

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
    _goalStartDateController.dispose();
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
      goalStartDate: _goalStartDate != null 
          ? DateFormat('yyyy-MM-dd').format(_goalStartDate!)
          : null,
      weeklyGoalRate: _weeklyGoalRate,
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
    
    // Populate goal start date
    if (profile.goalStartDate != null) {
      try {
        _goalStartDate = DateFormat('yyyy-MM-dd').parse(profile.goalStartDate!);
        _goalStartDateController.text = DateFormat('dd/MM/yyyy').format(_goalStartDate!);
      } catch (e) {
        // If parsing fails, leave empty
        _goalStartDate = null;
        _goalStartDateController.text = '';
      }
    } else {
      _goalStartDate = null;
      _goalStartDateController.text = '';
    }
    
    // Populate weekly goal rate
    _weeklyGoalRate = profile.weeklyGoalRate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        actions: [
          // Save button as text button with larger tap target
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextButton(
              onPressed: _onSave,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                minimumSize: const Size(64, 40), // Larger tap target
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'LƯU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Logout button with larger tap target
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              iconSize: 26,
              padding: const EdgeInsets.all(12.0), // Larger tap target
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar section - large circular area
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        border: Border.all(
                          color: Colors.green,
                          width: 3,
                        ),
                      ),
                      child: _avatarPath != null
                          ? ClipOval(
                              child: Image.network(
                                _avatarPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar();
                                },
                              ),
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text(
                      'Thay đổi ảnh đại diện',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Form fields
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Chiều cao',
                          border: OutlineInputBorder(),
                          suffixText: 'cm',
                          suffixStyle: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
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
                          labelText: 'Cân nặng',
                          border: OutlineInputBorder(),
                          suffixText: 'kg',
                          suffixStyle: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
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
                          labelText: 'Cân nặng mục tiêu',
                          border: OutlineInputBorder(),
                          suffixText: 'kg',
                          suffixStyle: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
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

                      // Activity level as chips
                      const Text(
                        'Mức độ hoạt động',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ActivityLevel.values.map((level) {
                          final isSelected = _activityLevel == level.name;
                          return FilterChip(
                            label: Text(_activityLevelToShortString(level)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _activityLevel = selected ? level.name : null;
                              });
                            },
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green.shade700,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.green.shade700 : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  
                  // 2. THÊM BIỂU ĐỒ VÀO ĐÂY
                  const SizedBox(height: 32),
                  // Hiển thị biểu đồ với animation
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Builder(
                      builder: (context) {
                        final currentWeight = double.tryParse(_weightController.text);
                        final targetWeight = double.tryParse(_targetWeightController.text);
                        return WeightChart(
                          currentWeight: currentWeight,
                          targetWeight: targetWeight,
                        );
                      },
                    ),
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

  String _activityLevelToShortString(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.SEDENTARY: return 'Ít vận động';
      case ActivityLevel.LIGHT: return 'Nhẹ';
      case ActivityLevel.MODERATE: return 'Trung bình';
      case ActivityLevel.ACTIVE: return 'Mạnh';
      case ActivityLevel.VERY_ACTIVE: return 'Rất mạnh';
    }
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.grey.shade400,
      ),
    );
  }

  Future<void> _pickAvatar() async {
    // TODO: Implement image picker functionality
    // For now, this is a placeholder
    // You can use image_picker package: final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   setState(() {
    //     _avatarPath = image.path;
    //   });
    // }
    
    // Show a dialog or snackbar for now
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tính năng tải ảnh đại diện sẽ được triển khai sớm'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

}