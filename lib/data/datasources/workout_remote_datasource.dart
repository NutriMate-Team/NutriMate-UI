import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/services/secure_storage_service.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_log_model.dart';
import '../../domain/entities/create_workout_log_dto.dart';

abstract class WorkoutRemoteDatasource {
  Future<List<ExerciseModel>> getExercises();
  Future<void> createWorkoutLog(CreateWorkoutLogDto dto);
  Future<List<WorkoutLogModel>> getTodayWorkoutLogs();
  Future<void> deleteWorkoutLog(String logId);
}

class WorkoutRemoteDatasourceImpl implements WorkoutRemoteDatasource {
  final http.Client client;
  final SecureStorageService storageService;

  WorkoutRemoteDatasourceImpl({
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
  Future<List<ExerciseModel>> getExercises() async {
    // Giả sử bạn đã có API GET /exercise (hoặc /exercises) trên Backend
    final response = await client.get(
      Uri.parse('$API_BASE_URL/exercises'), 
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ExerciseModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load exercises');
    }
  }

  @override
  Future<void> createWorkoutLog(CreateWorkoutLogDto dto) async {
    final response = await client.post(
      Uri.parse('$API_BASE_URL/workout-logs'),
      headers: await _getAuthHeaders(),
      body: json.encode(dto.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ServerException('Failed to create workout log');
    }
  }

  @override
  Future<List<WorkoutLogModel>> getTodayWorkoutLogs() async {
    final response = await client.get(
      Uri.parse('$API_BASE_URL/workout-logs/today'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => WorkoutLogModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load today\'s workout logs');
    }
  }

  @override
  Future<void> deleteWorkoutLog(String logId) async {
    final response = await client.delete(
      Uri.parse('$API_BASE_URL/workout-logs/$logId'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ServerException('Failed to delete workout log');
    }
  }
}