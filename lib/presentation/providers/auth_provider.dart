import 'package:flutter/material.dart';
import 'package:nutri_mate_ui/domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import 'package:nutri_mate_ui/domain/entities/user.dart'; 
import '../../core/error/failures.dart';
import '../../core/services/secure_storage_service.dart';

enum AuthStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final RegisterUser registerUser;
  final LoginUser loginUser;
  final SecureStorageService storageService;


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
  });


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


  Future<void> login(String email, String password) async {
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
      },
      (token) async { 
        await storageService.saveToken(token); 
        
        _token = token; 
        _status = AuthStatus.success;
        _errorMessage = '';
      },
    );

    notifyListeners();
  }
  
  Future<void> tryAutoLogin() async {
    final token = await storageService.readToken();
    if (token != null) {
      _token = token;
      _status = AuthStatus.success;
      // TODO: Thêm logic gọi API để fetch thông tin User
    } else {
      _status = AuthStatus.initial;
    }
    
    _isCheckingAuth = false;
    
    notifyListeners();
  }


  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await storageService.deleteToken();
    _token = null;
    _users = null; 
    _status = AuthStatus.initial;

    notifyListeners();
  }
}