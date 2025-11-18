import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/services/secure_storage_service.dart';
import '../../domain/entities/create_meal_log_dto.dart';

abstract class MealLogRemoteDatasource {
  Future<void> createMealLog(CreateMealLogDto dto);
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
      Uri.parse('$API_BASE_URL/meal-logs'), // API POST
      headers: await _getAuthHeaders(),
      body: json.encode(dto.toJson()),
    );

    if (response.statusCode != 201) {
      throw ServerException('Failed to create meal log');
    }
  }
}