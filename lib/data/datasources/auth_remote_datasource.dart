import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import 'package:nutri_mate_ui/domain/entities/user.dart';
import '../../core/error/exceptions.dart';

abstract class AuthRemoteDatasource {
  Future<String> login(String email, String password); 
  Future<Users> register(String email, String password, String fullname);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final http.Client client;
  AuthRemoteDatasourceImpl(this.client);

  @override
  Future<Users> register(String email, String password, String fullName) async {
    final response = await client.post(
      Uri.parse('$API_BASE_URL/auth/register'), 
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'fullname': fullName,
      }),
    );

    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      // Dùng fromJson để parse (sạch hơn)
      return Users.fromJson(jsonResponse['data']);
    } else {
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
      if (jsonResponse['token'] != null) {
        return jsonResponse['token'];
      } else {
        throw ServerException('Login failed: Token not found');
      }
    } else {
      final errorJson = json.decode(response.body);
      throw ServerException(errorJson['message'] ?? 'Failed to sign in');
    }
  }
}