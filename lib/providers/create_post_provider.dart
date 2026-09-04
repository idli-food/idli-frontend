import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/hotel.dart';
import '../services/post_service.dart';

part 'create_post_provider.g.dart';

enum UploadStage { idle, gettingUrl, uploadingMedia, creatingPost, done, error }

const ratingCategories = ['food', 'service', 'cleanliness', 'value'];

class CreatePostState {
  final File? selectedFile;
  final String mediaType;
  final String mediaContentType;
  final Hotel? selectedHotel;
  final UploadStage stage;
  final String? error;
  final Map<String, int> scores;
  final Map<String, String> reviews;

  const CreatePostState({
    this.selectedFile,
    this.mediaType = 'image',
    this.mediaContentType = 'image/jpeg',
    this.selectedHotel,
    this.stage = UploadStage.idle,
    this.error,
    this.scores = const {},
    this.reviews = const {},
  });

  bool get isLoading =>
      stage == UploadStage.gettingUrl ||
      stage == UploadStage.uploadingMedia ||
      stage == UploadStage.creatingPost;

  bool get ratingsComplete => ratingCategories.every((c) =>
      (scores[c] ?? 0) >= 1 && (reviews[c] ?? '').trim().isNotEmpty);

  List<Map<String, dynamic>> get ratingsPayload => ratingCategories
      .map((c) => {
            'category': c,
            'score': scores[c],
            'review': (reviews[c] ?? '').trim(),
          })
      .toList();

  CreatePostState copyWith({
    File? Function()? selectedFile,
    String? mediaType,
    String? mediaContentType,
    Hotel? Function()? selectedHotel,
    UploadStage? stage,
    String? Function()? error,
    Map<String, int>? scores,
    Map<String, String>? reviews,
  }) =>
      CreatePostState(
        selectedFile:
            selectedFile != null ? selectedFile() : this.selectedFile,
        mediaType: mediaType ?? this.mediaType,
        mediaContentType: mediaContentType ?? this.mediaContentType,
        selectedHotel:
            selectedHotel != null ? selectedHotel() : this.selectedHotel,
        stage: stage ?? this.stage,
        error: error != null ? error() : this.error,
        scores: scores ?? this.scores,
        reviews: reviews ?? this.reviews,
      );
}

@riverpod
class CreatePostNotifier extends _$CreatePostNotifier {
  final _service = PostService();

  @override
  CreatePostState build() => const CreatePostState();

  void setMedia(File file, String mediaType, String contentType) {
    state = state.copyWith(
      selectedFile: () => file,
      mediaType: mediaType,
      mediaContentType: contentType,
    );
  }

  void setHotel(Hotel hotel) {
    state = state.copyWith(selectedHotel: () => hotel);
  }

  void setScore(String category, int score) {
    state = state.copyWith(scores: {...state.scores, category: score});
  }

  void setReview(String category, String review) {
    state = state.copyWith(reviews: {...state.reviews, category: review});
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
    final hotel = state.selectedHotel;
    if (file == null || hotel == null || !state.ratingsComplete) return;

    debugPrint('[CreatePost] ▶ submit — title="$title" file=${file.path}');

    try {
      // Step 1: get signed S3 URL
      state = state.copyWith(stage: UploadStage.gettingUrl);
      final fileName = file.uri.pathSegments.last;
      final contentType = state.mediaContentType;
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
      debugPrint('[CreatePost] → createPost  mediaType=${state.mediaType}  key=$key  hotel=${hotel.id}');
      await _service.createPost(
        title: title,
        description: description,
        mediaType: state.mediaType,
        rawS3Key: key,
        hotelId: hotel.id,
        ratings: state.ratingsPayload,
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
