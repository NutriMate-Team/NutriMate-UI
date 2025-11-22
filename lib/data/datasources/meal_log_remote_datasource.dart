// file: lib/data/datasources/meal_log_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/services/secure_storage_service.dart';
import '../../domain/entities/create_meal_log_dto.dart';
import '../../models/meal_log_model.dart';

abstract class MealLogRemoteDatasource {
  Future<void> createMealLog(CreateMealLogDto dto);
  Future<List<MealLogModel>> getMealLogs();
  // 👇 THÊM DÒNG NÀY VÀO ĐỂ SỬA LỖI
  Future<void> deleteMealLog(String id); 
}

class MealLogRemoteDatasourceImpl implements MealLogRemoteDatasource {
  final http.Client client;
  final SecureStorageService storageService;

  MealLogRemoteDatasourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storageService.readToken();
    if (token == null) throw ServerException('Token is null');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<void> createMealLog(CreateMealLogDto dto) async {
    final response = await client.post(
      Uri.parse('$API_BASE_URL/meal-logs'),
      headers: await _getAuthHeaders(),
      body: json.encode(dto.toJson()),
    );
    if (response.statusCode != 201) {
      throw ServerException('Failed to create meal log');
    }
  }

  @override
  Future<List<MealLogModel>> getMealLogs() async {
    final response = await client.get(
      Uri.parse('$API_BASE_URL/meal-logs'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => MealLogModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load meal logs');
    }
  }

  // Hàm này giờ đã hợp lệ vì đã có trong abstract class
  @override 
  Future<void> deleteMealLog(String id) async {
    // Dùng hàm _getAuthHeaders cho gọn và tái sử dụng logic
    final headers = await _getAuthHeaders(); 

    final response = await client.delete(
      Uri.parse('$API_BASE_URL/meal-logs/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw ServerException('Failed to delete meal log');
    }
  }
}