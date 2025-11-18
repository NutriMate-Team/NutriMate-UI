import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../models/profile_model.dart';
import '../entities/update_profile_dto.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileModel>> getProfile();
  Future<Either<Failure, ProfileModel>> updateProfile(UpdateProfileDto dto);
}