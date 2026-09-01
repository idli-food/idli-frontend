class SavedThumb {
  final String id;
  final String? thumbnailUrl;
  final String? mediaType;

  const SavedThumb({
    required this.id,
    this.thumbnailUrl,
    this.mediaType,
  });

  bool get isVideo => mediaType == 'video';

  factory SavedThumb.fromJson(Map<String, dynamic> json) => SavedThumb(
        id: json['id'].toString(),
        thumbnailUrl: json['thumbnail_url'] as String?,
        mediaType: json['media_type'] as String?,
      );
}
