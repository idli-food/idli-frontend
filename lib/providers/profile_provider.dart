import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../utils/media_utils.dart';

part 'profile_provider.g.dart';

@riverpod
Future<UserProfile> profile(ProfileRef ref) async {
  return ProfileService().getProfile();
}

enum ProfileUpdateStage { idle, gettingUrl, uploadingAvatar, updating, done, error }

class ProfileUpdateState {
  final ProfileUpdateStage stage;
  final String? error;

  const ProfileUpdateState({
    this.stage = ProfileUpdateStage.idle,
    this.error,
  });

  bool get isLoading =>
      stage == ProfileUpdateStage.gettingUrl ||
      stage == ProfileUpdateStage.uploadingAvatar ||
      stage == ProfileUpdateStage.updating;

  ProfileUpdateState copyWith({
    ProfileUpdateStage? stage,
    String? Function()? error,
  }) =>
      ProfileUpdateState(
        stage: stage ?? this.stage,
        error: error != null ? error() : this.error,
      );
}

@riverpod
class CompleteProfileNotifier extends _$CompleteProfileNotifier {
  final _service = ProfileService();

  @override
  ProfileUpdateState build() => const ProfileUpdateState();

  void reset() => state = const ProfileUpdateState();

  void clearError() => state = state.copyWith(
        stage: ProfileUpdateStage.idle,
        error: () => null,
      );

  Future<void> submit({
    File? avatarFile,
    String? name,
    String? bio,
    String? dob,
    String? diet,
    String? foodPreference,
    double? lat,
    double? lon,
  }) async {
    debugPrint('[CompleteProfile] ▶ submit');
    try {
      String? avatarKey;

      if (avatarFile != null) {
        state = state.copyWith(stage: ProfileUpdateStage.gettingUrl);
        final fileName = avatarFile.uri.pathSegments.last;
        final contentType = contentTypeFromPath(avatarFile.path);
        debugPrint('[CompleteProfile] → getAvatarUploadUrl  file=$fileName');
        final (:uploadUrl, :key) =
            await _service.getAvatarUploadUrl(fileName, contentType);
        debugPrint('[CompleteProfile] ✓ got uploadUrl  key=$key');

        state = state.copyWith(stage: ProfileUpdateStage.uploadingAvatar);
        debugPrint('[CompleteProfile] → uploadAvatarToS3');
        await _service.uploadAvatarToS3(uploadUrl, avatarFile, contentType);
        debugPrint('[CompleteProfile] ✓ S3 upload complete');
        avatarKey = key;
      }

      state = state.copyWith(stage: ProfileUpdateStage.updating);
      debugPrint('[CompleteProfile] → updateProfile');
      await _service.updateProfile(
        name: name,
        bio: bio,
        dob: dob,
        diet: diet,
        foodPreference: foodPreference,
        avatar: avatarKey,
        lat: lat,
        lon: lon,
      );
      debugPrint('[CompleteProfile] ✓ profile updated');

      state = state.copyWith(stage: ProfileUpdateStage.done);
    } catch (e, stack) {
      debugPrint('[CompleteProfile] ✗ ERROR: $e');
      debugPrint('[CompleteProfile] stack: $stack');
      state = state.copyWith(
        stage: ProfileUpdateStage.error,
        error: () => e.toString(),
      );
    }
  }
}
