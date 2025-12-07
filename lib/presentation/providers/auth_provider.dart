import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutri_mate_ui/domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/validate_token.dart';
import 'package:nutri_mate_ui/domain/entities/user.dart'; 
import '../../core/error/failures.dart';
import '../../core/services/secure_storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

enum AuthStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final RegisterUser registerUser;
  final LoginUser loginUser;
  final ValidateToken? validateToken;
  final SecureStorageService storageService;
  final SharedPreferences? sharedPreferences;
  
  // IMPORTANT: Replace this with your Web Client ID from Google Cloud Console
  static const String _googleWebClientId =
      '880703023542-2obhv3cspe7r1vgb3a6gbmvanv3lk2ki.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: _googleWebClientId,
  );
  final http.Client _httpClient = http.Client();
  
  // Constants for SharedPreferences keys
  static const String _rememberedEmailKey = 'remembered_email';


  bool _isCheckingAuth = true;
  bool get isCheckingAuth => _isCheckingAuth;

  String? _token;
  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';
  

  Users? _users; 

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;

  Users? get user => _users; 
  String? get token => _token;

  AuthProvider({
    required this.registerUser,
    required this.loginUser,
    required this.storageService,
    this.sharedPreferences,
    this.validateToken,
  });
  
  /// Save email and password preferences if "Remember Me" is checked
  Future<void> saveCredentialsPreference(String email, String password, bool shouldRemember) async {
    if (shouldRemember) {
      // Save email to shared preferences
      if (sharedPreferences != null) {
        await sharedPreferences!.setString(_rememberedEmailKey, email);
      }
      // Save password to secure storage
      await storageService.savePassword(password);
    } else {
      // Clear saved credentials if user unchecks "Remember Me"
      await clearSavedCredentials();
    }
  }
  
  /// Load saved email from preferences
  Future<String?> loadSavedEmail() async {
    if (sharedPreferences == null) return null;
    return sharedPreferences!.getString(_rememberedEmailKey);
  }
  
  /// Load saved password from secure storage
  Future<String?> loadSavedPassword() async {
    return await storageService.readPassword();
  }
  
  /// Load both saved email and password
  Future<Map<String, String?>> loadSavedCredentials() async {
    final email = await loadSavedEmail();
    final password = await loadSavedPassword();
    return {
      'email': email,
      'password': password,
    };
  }
  
  /// Clear saved email and password (e.g., on logout or when unchecking Remember Me)
  Future<void> clearSavedCredentials() async {
    // Clear email from shared preferences
    if (sharedPreferences != null) {
      await sharedPreferences!.remove(_rememberedEmailKey);
    }
    // Clear password from secure storage
    await storageService.deletePassword();
  }
  
  /// Legacy method - kept for backward compatibility
  @Deprecated('Use saveCredentialsPreference instead')
  Future<void> saveEmailPreference(String email, bool shouldRemember) async {
    await saveCredentialsPreference(email, '', shouldRemember);
  }
  
  /// Legacy method - kept for backward compatibility
  @Deprecated('Use clearSavedCredentials instead')
  Future<void> clearSavedEmail() async {
    await clearSavedCredentials();
  }


  Future<void> register(String email, String password, String fullName) async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await registerUser(
      email: email,
      password: password,
      // LƯU Ý: Đảm bảo tên trường khớp với UseCase của bạn (fullname/fullName)
      fullname: fullName, 
    );

    result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = (failure is ServerFailure)
            ? failure.message
            : 'Connection error or data execute';
      },
      (user) {
        _status = AuthStatus.success;
        _users = user; 
        _errorMessage = '';
      },
    );
    notifyListeners();
  } 


  Future<void> login(String email, String password, {bool rememberMe = false}) async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await loginUser(
      email: email,
      password: password,
    );

    result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = (failure is ServerFailure) 
                       ? failure.message 
                       : 'Error to login';
        notifyListeners();
      },
      (token) async { 
        // Save token first
        await storageService.saveToken(token); 
        
        // Save credentials (email and password) if "Remember Me" is checked
        await saveCredentialsPreference(email, password, rememberMe);
        
        // Update state immediately after token is saved
        _token = token; 
        _status = AuthStatus.success;
        _errorMessage = '';
        
        // Notify listeners to trigger UI rebuild and navigation
        notifyListeners();
      },
    );
  }
  
  /// Checks for existing authentication token and updates state accordingly.
  /// This should be called on app startup to restore user session.
  /// Validates the token with the backend to ensure it's still valid.
  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final token = await storageService.readToken();
      
      if (token != null && token.isNotEmpty) {
        // Token found - validate it with backend
        _token = token;
        
        // If validateToken use case is available, validate with backend
        if (validateToken != null) {
          final result = await validateToken!();
          
          result.fold(
            (failure) {
              // Token is invalid or expired - clear it
              _token = null;
              _status = AuthStatus.initial;
              _errorMessage = '';
              // Clear invalid token from storage
              storageService.deleteToken();
            },
            (validationResult) {
              // Token is valid - user is authenticated
              if (validationResult['valid'] == true && validationResult['user'] != null) {
                final userData = validationResult['user'] as Map<String, dynamic>;
                _users = Users.fromJson(userData);
                _status = AuthStatus.success;
                _errorMessage = '';
              } else {
                // Invalid response - clear token
                _token = null;
                _status = AuthStatus.initial;
                _errorMessage = '';
                storageService.deleteToken();
              }
            },
          );
        } else {
          // Fallback: if validateToken is not available, just check token existence
          _status = AuthStatus.success;
          _errorMessage = '';
        }
      } else {
        // No token found - user is not authenticated
        _token = null;
        _status = AuthStatus.initial;
        _errorMessage = '';
      }
    } catch (e) {
      // Error reading token or validating - treat as not authenticated
      _token = null;
      _status = AuthStatus.initial;
      _errorMessage = '';
      // Clear any potentially corrupted token
      try {
        await storageService.deleteToken();
      } catch (_) {
        // Ignore errors when deleting token
      }
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  /// Legacy method name - calls checkAuthStatus for backward compatibility
  @Deprecated('Use checkAuthStatus() instead')
  Future<void> tryAutoLogin() async {
    await checkAuthStatus();
  }


  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    // Clear JWT token (session) but preserve saved credentials for "Remember Me"
    await storageService.deleteToken();
    await _googleSignIn.signOut();
    
    // IMPORTANT: Do NOT clear saved email/password here
    // Credentials are only cleared when:
    // 1. User unchecks "Remember Me" checkbox during login
    // 2. User explicitly requests credential clearing
    // This allows credentials to persist across logout/login cycles
    
    _token = null;
    _users = null; 
    _status = AuthStatus.initial;

    notifyListeners();
  }

  Future<String?> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      
      // Handle user cancellation - return null without treating as error
      if (account == null) {
        _status = AuthStatus.initial;
        notifyListeners();
        return null;
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _status = AuthStatus.error;
        _errorMessage = 'Unable to retrieve Google ID token.';
        notifyListeners();
        return null;
      }

      try {
        final response = await _httpClient.post(
          Uri.parse('$API_BASE_URL/google/verify'),
          headers: {'Content-Type': 'application/json'},
          body: '{"token": "$idToken"}',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final token = response.body.isNotEmpty ? response.body : null;
          if (token == null) {
            _status = AuthStatus.error;
            _errorMessage = 'Invalid token received from server.';
            notifyListeners();
            return null;
          } else {
            _token = token;
            await storageService.saveToken(token);
            _status = AuthStatus.success;
            notifyListeners();
            return idToken;
          }
        } else {
          _status = AuthStatus.error;
          _errorMessage =
              'Google Sign-In failed (status code: ${response.statusCode}).';
          notifyListeners();
          return null;
        }
      } catch (e) {
        _status = AuthStatus.error;
        _errorMessage =
            'Sign-In failed. Please check your network connection and try again.';
        notifyListeners();
        return null;
      }
    } on PlatformException catch (e) {
      // Handle Platform/API errors with specific error codes
      _status = AuthStatus.error;
      
      // Check for configuration mismatch (ApiException: 10 or similar error codes)
      if (e.code == '10' || 
          e.code == 'sign_in_failed' || 
          e.message?.contains('10') == true ||
          e.message?.toLowerCase().contains('configuration') == true) {
        _errorMessage = 
            'Google Sign-In failed due to a configuration error. Please contact support.';
      } else {
        // Other platform errors (network issues, etc.)
        _errorMessage = 
            'Sign-In failed. Please check your network connection and try again.';
      }
      
      notifyListeners();
      return null;
    } on Exception catch (e) {
      // Handle general exceptions
      _status = AuthStatus.error;
      
      // Check if it's a configuration-related error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('10') || 
          errorString.contains('configuration') ||
          errorString.contains('api exception')) {
        _errorMessage = 
            'Google Sign-In failed due to a configuration error. Please contact support.';
      } else {
        _errorMessage = 
            'Sign-In failed. Please check your network connection and try again.';
      }
      
      notifyListeners();
      return null;
    } catch (e) {
      // Catch any other unexpected errors
      _status = AuthStatus.error;
      _errorMessage = 
          'Sign-In failed. Please check your network connection and try again.';
      notifyListeners();
      return null;
    }
  }
}