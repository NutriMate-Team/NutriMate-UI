import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/profile_repository.dart';
import '../../models/profile_model.dart';
import '../entities/update_profile_dto.dart';

// UseCase 1
class GetUserProfile {
  final ProfileRepository repository;
  GetUserProfile(this.repository);

  Future<Either<Failure, ProfileModel>> call() async {
    return await repository.getProfile();
  }
}

// UseCase 2
class UpdateUserProfile {
  final ProfileRepository repository;
  UpdateUserProfile(this.repository);

  Future<Either<Failure, ProfileModel>> call(UpdateProfileDto dto) async {
    return await repository.updateProfile(dto);
  }
}

// UseCase 3
class UpdateProfilePicture {
  final ProfileRepository repository;
  UpdateProfilePicture(this.repository);

  Future<Either<Failure, String>> call(File imageFile) async {
    return await repository.updateProfilePicture(imageFile);
  }
}