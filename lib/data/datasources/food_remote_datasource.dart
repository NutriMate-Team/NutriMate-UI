import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/services/secure_storage_service.dart';
import '../../models/food_model.dart';

abstract class FoodRemoteDatasource {
  Future<List<FoodModel>> searchFood(String query);
  Future<FoodModel> searchBarcode(String code);
}

class FoodRemoteDatasourceImpl implements FoodRemoteDatasource {
  final http.Client client;
  final SecureStorageService storageService;

  FoodRemoteDatasourceImpl({
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
  Future<List<FoodModel>> searchFood(String query) async {
    final response = await client.get(
      Uri.parse('$API_BASE_URL/food/search?q=$query'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => FoodModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to search food');
    }
  }

  @override
  Future<FoodModel> searchBarcode(String code) async {
    final response = await client.get(
      Uri.parse('$API_BASE_URL/food/barcode/$code'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return FoodModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to find barcode');
    }
  }
}