import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../models/profile_model.dart';
import '../../domain/entities/update_profile_dto.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ProfileModel>> getProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final profile = await remoteDatasource.getProfile();
        return Right(profile);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }

  @override
  Future<Either<Failure, ProfileModel>> updateProfile(UpdateProfileDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final profile = await remoteDatasource.updateProfile(dto);
        return Right(profile);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(const ConnectionFailure());
    }
  }
}