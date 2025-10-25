import 'package:dartz/dartz.dart';
import 'package:nutri_mate_ui/domain/entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../core/error/failures.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  Future<Either<Failure, Users>> call ({
    required String email,
    required String password,
    required String fullname,
  }) async {
    return await repository.register(email: email, password: password, fullname: fullname);
  }
}