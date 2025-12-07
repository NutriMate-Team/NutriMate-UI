import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/profile_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart'; 
import '../../../domain/entities/update_profile_dto.dart';
import '../../../models/profile_model.dart';
import '../../../constants/api_constants.dart';
import '../../widgets/weight_chart.dart'; 
import '../auth/login_screen.dart';

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
  File? _selectedImageFile; // File object for upload (temporary local state)
  bool _isUploadingImage = false; // Track upload status
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

  Widget _buildSavingIndicator(ProfileProvider provider) {
    if (provider.status == ProfileStatus.loading && !_isInit) {
      return const Padding(
        padding: EdgeInsets.only(top: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
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
    const primaryGreen = Color(0xFF4CAF50);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Hồ sơ của tôi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Logout button in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              iconSize: 24,
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture Section - Larger with camera overlay
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAvatar,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[200],
                                  border: Border.all(
                                    color: primaryGreen,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildAvatarImage(provider),
                              ),
                              // Camera icon overlay
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryGreen,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _isUploadingImage
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isUploadingImage ? 'Đang tải lên...' : 'Nhấn để thay đổi ảnh đại diện',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                  
                        // Stats Group Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thông tin cơ bản',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _heightController,
                                decoration: InputDecoration(
                                  labelText: 'Chiều cao',
                                  labelStyle: TextStyle(color: Colors.grey[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                  suffixText: 'cm',
                                  suffixStyle: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
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
                                decoration: InputDecoration(
                                  labelText: 'Cân nặng',
                                  labelStyle: TextStyle(color: Colors.grey[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                  suffixText: 'kg',
                                  suffixStyle: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Goals Group Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mục tiêu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _targetWeightController,
                                decoration: InputDecoration(
                                  labelText: 'Cân nặng mục tiêu',
                                  labelStyle: TextStyle(color: Colors.grey[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                  suffixText: 'kg',
                                  suffixStyle: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Activity Level Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mức độ hoạt động',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Modern Segmented Control using ToggleButtons (horizontally scrollable)
                              _buildActivityLevelSelector(),
                            ],
                          ),
                        ),
                        // Progress Chart Section - Focal point with ample space
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: primaryGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tiến trình cân nặng',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Chart with fixed height to prevent overflow
                              AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 500),
                                child: Builder(
                                  builder: (context) {
                                    final currentWeight = double.tryParse(_weightController.text);
                                    final targetWeight = double.tryParse(_targetWeightController.text);
                                    // Fixed height chart to prevent overflow
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 250.0, // Fixed height to prevent overflow
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: double.infinity,
                                          height: 250.0,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: double.infinity,
                                              maxHeight: 234.0, // 250 - 16 (padding)
                                            ),
                                            child: WeightChart(
                                              currentWeight: currentWeight,
                                              targetWeight: targetWeight,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSavingIndicator(provider),
                        const SizedBox(height: 24),
                        // Save Button inside scroll view
                        Consumer<ProfileProvider>(
                          builder: (context, provider, child) {
                            final isLoading = provider.status == ProfileStatus.loading && !_isInit;
                            return SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _onSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 3,
                                  shadowColor: primaryGreen.withOpacity(0.3),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.save,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'LƯU THAY ĐỔI',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityLevelSelector() {
    const primaryGreen = Color(0xFF4CAF50);
    
    // Wrap in SingleChildScrollView to prevent horizontal overflow
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ActivityLevel.values.map((level) {
          final isSelected = _activityLevel == level.name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _activityLevelToShortString(level),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _activityLevel = selected ? level.name : null;
                });
              },
              selectedColor: primaryGreen,
              backgroundColor: Colors.grey[200],
              side: BorderSide(
                color: isSelected ? primaryGreen : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
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
        size: 70,
        color: Colors.grey.shade400,
      ),
    );
  }

  /// Converts localhost URLs to Android emulator-compatible URLs
  /// Android emulators cannot resolve 'localhost', so we use '10.0.2.2' instead
  String _getDisplayUrl(String url) {
    // Check if running on Android emulator where localhost won't resolve
    if (!kIsWeb && Platform.isAndroid && url.contains('localhost')) {
      // Replace localhost with 10.0.2.2 (Android emulator's host machine loopback)
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  Widget _buildAvatarImage(ProfileProvider provider) {
    const avatarSize = 140.0;
    
    // Priority order for image source:
    // 1. Provider's profilePictureUrl (from backend) - HIGHEST PRIORITY after upload
    // 2. Selected local file (temporary preview during selection)
    // 3. Default avatar (fallback)
    
    // Check provider's profilePictureUrl FIRST - this ensures network image shows immediately after upload
    if (provider.profilePictureUrl != null && provider.profilePictureUrl!.isNotEmpty) {
      // Construct full URL - profilePictureUrl from backend is already a full URL (http://...)
      final imageUrl = provider.profilePictureUrl!.startsWith('http')
          ? provider.profilePictureUrl!
          : '$API_BASE_URL${provider.profilePictureUrl}';
      
      // Convert localhost to Android emulator-compatible URL (10.0.2.2)
      final displayUrl = _getDisplayUrl(imageUrl);
      
      // Add cache-busting parameter using version counter (only changes on upload)
      final cacheBustingUrl = '$displayUrl?v=${provider.profilePictureVersion}';
      
      // CRITICAL: Use NetworkImage to display the image from the backend URL
      return ClipOval(
        child: Image.network(
          cacheBustingUrl,
          fit: BoxFit.cover,
          width: avatarSize,
          height: avatarSize,
          // CRITICAL: Key ensures widget rebuilds when URL or version changes
          key: ValueKey('${provider.profilePictureUrl}_${provider.profilePictureVersion}'),
          cacheWidth: avatarSize.toInt(), // Optimize memory usage
          cacheHeight: avatarSize.toInt(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // If network image fails, fall back to default avatar
            return _buildDefaultAvatar();
          },
        ),
      );
    } else if (_selectedImageFile != null) {
      // Show selected local file as temporary preview (only if no provider URL exists)
      return ClipOval(
        child: Image.file(
          _selectedImageFile!,
          fit: BoxFit.cover,
          width: avatarSize,
          height: avatarSize,
          key: ValueKey(_selectedImageFile!.path), // Force rebuild on file change
        ),
      );
    } else {
      // Default avatar when no image is available
      return _buildDefaultAvatar();
    }
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    
    // Show dialog to choose source
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ảnh đại diện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Máy ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final imageFile = File(image.path);
        
        // CRITICAL: Update local state immediately to show selected image
        setState(() {
          _selectedImageFile = imageFile;
          _isUploadingImage = false; // Reset upload state
        });

        // Upload the image asynchronously (don't block UI)
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        
        // Set uploading state
        setState(() {
          _isUploadingImage = true;
        });

        // Perform upload
        final success = await profileProvider.uploadProfilePicture(imageFile);

        if (mounted) {
          if (success) {
            // CRITICAL: Clear local file reference IMMEDIATELY after successful upload
            // This ensures the Consumer rebuild (triggered by notifyListeners) will show
            // the network image from provider.profilePictureUrl instead of the local file
            setState(() {
              _selectedImageFile = null;
              _isUploadingImage = false;
            });
            
            // The Provider has already called notifyListeners(), which will trigger
            // the Consumer to rebuild and display the new network image
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cập nhật ảnh đại diện thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Keep the selected image if upload failed so user can retry
            setState(() {
              _isUploadingImage = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${profileProvider.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}