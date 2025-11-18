import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/services/secure_storage_service.dart';
import '../../models/profile_model.dart';
import '../../domain/entities/update_profile_dto.dart'; // (Chúng ta sẽ tạo file này)

abstract class ProfileRemoteDatasource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile(UpdateProfileDto dto);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final http.Client client;
  final SecureStorageService storageService;

  ProfileRemoteDatasourceImpl({
    required this.client,
    required this.storageService,
  });

  // Hàm trợ giúp để lấy header (dùng cho cả 2 request)
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storageService.readToken();
    if (token == null) throw ServerException('Token is null');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<ProfileModel> getProfile() async {
    final response = await client.get(
      Uri.parse('$API_BASE_URL/user-profile'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return ProfileModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to load profile');
    }
  }

  @override
  Future<ProfileModel> updateProfile(UpdateProfileDto dto) async {
    final response = await client.patch(
      Uri.parse('$API_BASE_URL/user-profile'),
      headers: await _getAuthHeaders(),
      body: json.encode(dto.toJson()), 
    );
    if (response.statusCode == 200) {
      return ProfileModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to update profile');
    }
  }
}