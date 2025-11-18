import 'package:flutter/material.dart';
import '../../domain/usecases/profile_usecases.dart'; 
import '../../models/profile_model.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/update_profile_dto.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileProvider extends ChangeNotifier {
  final GetUserProfile getUserProfile;
  final UpdateUserProfile updateUserProfile;

  ProfileStatus _status = ProfileStatus.initial;
  String _errorMessage = '';
  ProfileModel? _profile;

  // Getters
  ProfileStatus get status => _status;
  String get errorMessage => _errorMessage;
  ProfileModel? get profile => _profile;

  ProfileProvider({
    required this.getUserProfile,
    required this.updateUserProfile,
  });

  // Hàm tải profile (gọi khi vào màn hình)
  Future<void> fetchProfile() async {
    _status = ProfileStatus.loading;
    notifyListeners();

    final result = await getUserProfile();
    result.fold(
      (failure) {
        _status = ProfileStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
      },
      (profileModel) {
        _status = ProfileStatus.success;
        _profile = profileModel;
      },
    );
    notifyListeners();
  }

  // Hàm cập nhật profile (gọi khi nhấn "Lưu")
  Future<bool> saveProfile(UpdateProfileDto dto) async {
    _status = ProfileStatus.loading;
    notifyListeners();

    final result = await updateUserProfile(dto);
    bool success = false;
    
    result.fold(
      (failure) {
        _status = ProfileStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
        success = false;
      },
      (profileModel) {
        _status = ProfileStatus.success;
        _profile = profileModel; // Cập nhật profile mới
        success = true;
      },
    );
    
    notifyListeners();
    return success; // Trả về true nếu thành công
  }
}