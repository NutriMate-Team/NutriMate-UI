import 'package:flutter/material.dart';
import 'package:nutri_mate_ui/domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import 'package:nutri_mate_ui/domain/entities/user.dart';
import '../../core/error/failures.dart';

enum AuthStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final RegisterUser registerUser;
  final LoginUser loginUser;

  String? _token;

  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';
  Users? _users;

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  Users? get users => _users;
  String? get token => _token;

  AuthProvider({required this.registerUser, required this.loginUser});

  Future<void> register(String email, String password, String fullName) async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await registerUser(
      email: email,
      password: password,
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

    final result = await loginUser(email: email, password: password);

    result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = (failure is ServerFailure)
            ? failure.message
            : 'Login Error.';
      },
      (token) {
        _token = token;
        _status = AuthStatus.success;
        _errorMessage = '';
      },
    );
    notifyListeners();
  }
}