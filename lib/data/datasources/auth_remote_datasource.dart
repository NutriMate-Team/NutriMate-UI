import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import 'package:nutri_mate_ui/domain/entities/user.dart';
import '../../core/error/exceptions.dart';
import '../../core/services/secure_storage_service.dart';

abstract class AuthRemoteDatasource {
  Future<String> login(String email, String password); 
  Future<Users> register(String email, String password, String fullName);
  Future<Map<String, dynamic>> validateToken();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final http.Client client;
  final SecureStorageService storageService;
  
  AuthRemoteDatasourceImpl(this.client, this.storageService);


  @override
  Future<Users> register(String email, String password, String fullName) async {
    final response = await client.post(
      Uri.parse('$API_BASE_URL/auth/register'), 
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        // LƯU Ý: Phải khớp với tên trường DTO (fullName) của Backend NestJS
        'fullname': fullName, 
      }),
    );

    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      // Giả định NestJS trả về User Entity trực tiếp
      return Users.fromJson(jsonResponse); 
    } else {
      // Xử lý lỗi (Email đã tồn tại, validation...)
      final errorJson = json.decode(response.body);
      throw ServerException(errorJson['message'] ?? 'Failed to sign up');
    }
  }


  @override
  Future<String> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$API_BASE_URL/auth/login'), 
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      
      final token = jsonResponse['access_token'];

      if (token != null) {
        return token; 
      } else {
        throw ServerException('Login failed: Token not found in response payload');
      }
    } else {
      final errorJson = json.decode(response.body);
      throw ServerException(errorJson['message'] ?? 'Invalid email or password');
    }
  }

  @override
  Future<Map<String, dynamic>> validateToken() async {
    final token = await storageService.readToken();
    if (token == null) {
      throw ServerException('No token available');
    }

    final response = await client.get(
      Uri.parse('$API_BASE_URL/auth/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      // Token is invalid or expired
      throw ServerException('Token expired or invalid');
    } else {
      final errorJson = json.decode(response.body);
      throw ServerException(errorJson['message'] ?? 'Token validation failed');
    }
  }
}