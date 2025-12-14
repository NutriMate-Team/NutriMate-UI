import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/services/secure_storage_service.dart';
import '../../models/profile_model.dart';
import '../../domain/entities/update_profile_dto.dart'; // (Chúng ta sẽ tạo file này)

abstract class ProfileRemoteDatasource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile(UpdateProfileDto dto);
  Future<String> updateProfilePicture(File imageFile);
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

  @override
  Future<String> updateProfilePicture(File imageFile) async {
    final token = await storageService.readToken();
    if (token == null) throw ServerException('Token is null');

    // Create multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$API_BASE_URL/user-profile/picture'),
    );

    // Add authorization header
    request.headers['Authorization'] = 'Bearer $token';

    // Add file to request
    final fileStream = http.ByteStream(imageFile.openRead());
    final fileLength = await imageFile.length();
    final multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: imageFile.path.split('/').last,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      final profilePictureUrl = jsonResponse['profilePictureUrl'] as String?;
      
      if (profilePictureUrl == null || profilePictureUrl.isEmpty) {
        throw ServerException('Profile picture URL not returned from server');
      }
      
      return profilePictureUrl;
    } else {
      final errorBody = response.body;
      String errorMessage = 'Failed to upload profile picture';
      
      try {
        final errorJson = json.decode(errorBody);
        final dynamic rawMessage = errorJson['message'];
        if (rawMessage == null) {
          errorMessage = errorMessage;
        } else if (rawMessage is List) {
          errorMessage = rawMessage.join(', ');
        } else {
          errorMessage = rawMessage.toString();
        }
      } catch (e) {
        // If JSON parsing fails, use the raw response body or status code
        errorMessage = 'Upload failed with status ${response.statusCode}';
      }
      
      throw ServerException(errorMessage);
    }
  }
}