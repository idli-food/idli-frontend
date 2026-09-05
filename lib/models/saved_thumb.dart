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

  factory SavedThumb.fromJson(Map<String, dynamic> json) {
    final mediaList = json['media'] as List<dynamic>?;
    final firstMedia = (mediaList != null && mediaList.isNotEmpty)
        ? mediaList.first as Map<String, dynamic>
        : null;
    return SavedThumb(
      id: json['id'].toString(),
      thumbnailUrl:
          (firstMedia?['thumbnail_url'] ?? json['thumbnail_url']) as String?,
      mediaType: (firstMedia?['content_type'] ?? json['media_type']) as String?,
    );
  }
}
