import 'package:dartz/dartz.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'package:nutri_mate_ui/domain/entities/user.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../core/network/network_info.dart';

class AuthRepositoryImpl implements AuthRepository{
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.localDataSource, 
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Users>> register({
    required String email,
    required String password,
    required String fullname,
  }) async {
    try {
      final users = await remoteDatasource.register(email, password, fullname);
      return Right(users);
    }on ServerException catch(e) {
      return Left(ServerFailure(e.message));
    }on Exception {
      return Left(const ConnectionFailure());
    }
  }

  @override
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final token = await remoteDatasource.login(email, password);
      return Right(token);
    }on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception {
      return Left(const ConnectionFailure());
    }
  }
  

}