import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/exceptions.dart'; 

const String CACHED_AUTH_TOKEN = 'CACHED_AUTH_TOKEN';

abstract class AuthLocalDataSource {
  Future<void> cacheAuthToken(String token);
  Future<String> getLastAuthToken();
  Future<void> clearAuthToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheAuthToken(String token) {
    return sharedPreferences.setString(CACHED_AUTH_TOKEN, token);
  }

  @override
  Future<String> getLastAuthToken() {
    final token = sharedPreferences.getString(CACHED_AUTH_TOKEN);
    if (token != null) {
      return Future.value(token);
    } else {
      throw CacheException(); 
    }
  }

  @override
  Future<void> clearAuthToken() {
    return sharedPreferences.remove(CACHED_AUTH_TOKEN);
  }
}