import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _AUTH_TOKEN_KEY = 'auth_token';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: _AUTH_TOKEN_KEY, value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: _AUTH_TOKEN_KEY);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _AUTH_TOKEN_KEY);
  }
}