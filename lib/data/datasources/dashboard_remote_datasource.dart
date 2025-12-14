import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nutri_mate_ui/constants/api_constants.dart';
import 'package:nutri_mate_ui/core/error/exceptions.dart';
import 'package:nutri_mate_ui/core/services/secure_storage_service.dart';
import 'package:nutri_mate_ui/models/dashboard_model.dart';

abstract class DashboardRemoteDatasource {
  Future<DashboardModel> getSummary();
}

class DashboardRemoteDatasourceImpl implements DashboardRemoteDatasource {
  final http.Client client;
  final SecureStorageService storageService;

  DashboardRemoteDatasourceImpl({
    required this.client,
    required this.storageService, 
  });

  @override
  Future<DashboardModel> getSummary() async {
    final token = await storageService.readToken();
    if (token == null) {
      throw ServerException('Token is null, user is not logged in.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', 
    };

    final response = await client.get(
      Uri.parse('$API_BASE_URL/dashboard/summary'),
      headers: headers, 
    );

    if (response.statusCode == 200) {
      return DashboardModel.fromJson(json.decode(response.body));
    } else {
      final errorJson = json.decode(response.body);
      final dynamic rawMessage = errorJson['message'];
      final String message;
      if (rawMessage == null) {
        message = 'Failed to load summary';
      } else if (rawMessage is List) {
        message = rawMessage.join(', ');
      } else {
        message = rawMessage.toString();
      }
      throw ServerException(message);
    }
  }
}