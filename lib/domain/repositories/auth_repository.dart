import 'package:dartz/dartz.dart';
import 'package:nutri_mate_ui/domain/entities/user.dart';
import '../../core/error/failures.dart';


abstract class AuthRepository {
  Future<Either<Failure, Users>> register({
    required String email,
    required String password,
    required String fullname,
  });

  Future<Either<Failure, String>> login ({
    required String email,
    required String password,
  });
}