import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../../core/error/failures.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<Either<Failure, String>> call({
    required String email,
    required String password,
  }) async {
    return await repository.login(
      email: email,
      password: password,
    );
  }
}