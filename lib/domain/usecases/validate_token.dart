import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../../core/error/failures.dart';

class ValidateToken {
  final AuthRepository repository;

  ValidateToken(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call() async {
    return await repository.validateToken();
  }
}

