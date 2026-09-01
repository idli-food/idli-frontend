import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/post_service.dart';
import '../utils/location_result.dart';
import '../utils/media_utils.dart';

part 'create_post_provider.g.dart';

enum UploadStage { idle, gettingUrl, uploadingMedia, creatingPost, done, error }

class CreatePostState {
  final File? selectedFile;
  final String mediaType;
  final UploadStage stage;
  final String? error;
  final LocationResult? selectedLocation;

  const CreatePostState({
    this.selectedFile,
    this.mediaType = 'image',
    this.stage = UploadStage.idle,
    this.error,
    this.selectedLocation,
  });

  bool get isLoading =>
      stage == UploadStage.gettingUrl ||
      stage == UploadStage.uploadingMedia ||
      stage == UploadStage.creatingPost;

  CreatePostState copyWith({
    File? Function()? selectedFile,
    String? mediaType,
    UploadStage? stage,
    String? Function()? error,
    LocationResult? Function()? selectedLocation,
  }) =>
      CreatePostState(
        selectedFile:
            selectedFile != null ? selectedFile() : this.selectedFile,
        mediaType: mediaType ?? this.mediaType,
        stage: stage ?? this.stage,
        error: error != null ? error() : this.error,
        selectedLocation:
            selectedLocation != null ? selectedLocation() : this.selectedLocation,
      );
}

@riverpod
class CreatePostNotifier extends _$CreatePostNotifier {
  final _service = PostService();

  @override
  CreatePostState build() => const CreatePostState();

  void setMedia(File file, String mediaType) {
    state = state.copyWith(
      selectedFile: () => file,
      mediaType: mediaType,
    );
  }

  void setLocation(LocationResult location) {
    state = state.copyWith(selectedLocation: () => location);
  }

  void reset() => state = const CreatePostState();

  void clearError() {
    state = state.copyWith(
      stage: UploadStage.idle,
      error: () => null,
    );
  }

  Future<void> submit({
    required String title,
    required String description,
  }) async {
    final file = state.selectedFile;
    if (file == null) return;

    debugPrint('[CreatePost] ▶ submit — title="$title" file=${file.path}');

    try {
      // Step 1: get signed S3 URL
      state = state.copyWith(stage: UploadStage.gettingUrl);
      final fileName = file.uri.pathSegments.last;
      final contentType = contentTypeFromPath(file.path);
      debugPrint('[CreatePost] → getUploadUrl  fileName=$fileName  contentType=$contentType');
      final (:uploadUrl, :key) =
          await _service.getUploadUrl(fileName, contentType);
      debugPrint('[CreatePost] ✓ got uploadUrl  key=$key');

      // Step 2: upload file directly to S3
      state = state.copyWith(stage: UploadStage.uploadingMedia);
      debugPrint('[CreatePost] → uploadToS3  url=${uploadUrl.substring(0, 60)}…');
      await _service.uploadToS3(uploadUrl, file, contentType);
      debugPrint('[CreatePost] ✓ S3 upload complete');

      // Step 3: create post metadata
      state = state.copyWith(stage: UploadStage.creatingPost);
      debugPrint('[CreatePost] → createPost  mediaType=${mediaTypeFromPath(file.path)}  key=$key');
      final loc = state.selectedLocation;
      await _service.createPost(
        title: title,
        description: description,
        mediaType: mediaTypeFromPath(file.path),
        rawS3Key: key,
        latitude: loc?.latitude ?? 9.9312,
        longitude: loc?.longitude ?? 76.2673,
      );
      debugPrint('[CreatePost] ✓ post created successfully');

      state = state.copyWith(stage: UploadStage.done);
    } catch (e, stack) {
      debugPrint('[CreatePost] ✗ ERROR: $e');
      debugPrint('[CreatePost] stack: $stack');
      state = state.copyWith(
        stage: UploadStage.error,
        error: () => e.toString(),
      );
    }
  }
}
