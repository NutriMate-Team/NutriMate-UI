import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _AUTH_TOKEN_KEY = 'auth_token';
const String _REMEMBERED_PASSWORD_KEY = 'remembered_password';

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

  /// Save password securely (for Remember Me feature)
  Future<void> savePassword(String password) async {
    await _storage.write(key: _REMEMBERED_PASSWORD_KEY, value: password);
  }

  /// Load saved password
  Future<String?> readPassword() async {
    return await _storage.read(key: _REMEMBERED_PASSWORD_KEY);
  }

  /// Clear saved password
  Future<void> deletePassword() async {
    await _storage.delete(key: _REMEMBERED_PASSWORD_KEY);
  }
}