import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/usecases/profile_usecases.dart'; 
import '../../models/profile_model.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/update_profile_dto.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileProvider extends ChangeNotifier {
  final GetUserProfile getUserProfile;
  final UpdateUserProfile updateUserProfile;
  final UpdateProfilePicture? updateProfilePicture;

  ProfileStatus _status = ProfileStatus.initial;
  String _errorMessage = '';
  ProfileModel? _profile;
  String? _profilePictureUrl;
  int _profilePictureVersion = 0; // Version counter to force image reload on upload

  // Getters
  ProfileStatus get status => _status;
  String get errorMessage => _errorMessage;
  ProfileModel? get profile => _profile;
  String? get profilePictureUrl => _profilePictureUrl;
  int get profilePictureVersion => _profilePictureVersion; // Expose version for cache-busting

  ProfileProvider({
    required this.getUserProfile,
    required this.updateUserProfile,
    this.updateProfilePicture,
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
        // Update profile picture URL from profile model
        _profilePictureUrl = profileModel.profilePictureUrl;
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

  // Hàm cập nhật ảnh đại diện
  Future<bool> uploadProfilePicture(File imageFile) async {
    if (updateProfilePicture == null) {
      _status = ProfileStatus.error;
      _errorMessage = 'Update profile picture use case not available';
      notifyListeners();
      return false;
    }

    _status = ProfileStatus.loading;
    notifyListeners();

    final result = await updateProfilePicture!(imageFile);
    bool success = false;

    result.fold(
      (failure) {
        _status = ProfileStatus.error;
        _errorMessage = (failure is ServerFailure) ? failure.message : 'Lỗi kết nối';
        success = false;
        // CRITICAL: Notify listeners on error as well
        notifyListeners();
      },
      (profilePictureUrl) {
        // Update state synchronously before notifying listeners
        _status = ProfileStatus.success;
        
        // Update the profile picture URL - this is the primary state update
        _profilePictureUrl = profilePictureUrl;
        
        // Increment version counter to force image reload (cache-busting)
        _profilePictureVersion++;
        
        // Update profile model's profilePictureUrl if profile exists
        // This ensures consistency between _profilePictureUrl and _profile.profilePictureUrl
        if (_profile != null) {
          _profile = ProfileModel(
            userId: _profile!.userId,
            heightCm: _profile!.heightCm,
            weightKg: _profile!.weightKg,
            targetWeightKg: _profile!.targetWeightKg,
            activityLevel: _profile!.activityLevel,
            bmi: _profile!.bmi,
            goalStartDate: _profile!.goalStartDate,
            weeklyGoalRate: _profile!.weeklyGoalRate,
            profilePictureUrl: profilePictureUrl, // Update with new URL from backend
          );
        }
        
        success = true;
        
        // Notify listeners immediately after ALL state updates are complete
        // This triggers UI rebuild in all Consumer widgets
        notifyListeners();
      },
    );

    return success;
  }
}