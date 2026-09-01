class FeedPost {
  final String id;
  final String title;
  final String username;
  final String? avatarUrl;
  final String description;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? mediaType;
  final int likeCount;
  final double avgRating;
  final double compositeScore;
  final DateTime createdAt;
  final bool isLiked;
  final bool isSaved;
  final int commentCount;
  final double? latitude;
  final double? longitude;
  final int? myRating;

  const FeedPost({
    required this.id,
    required this.title,
    required this.username,
    this.avatarUrl,
    required this.description,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaType,
    required this.likeCount,
    required this.avgRating,
    required this.compositeScore,
    required this.createdAt,
    this.isLiked = false,
    this.isSaved = false,
    this.commentCount = 0,
    this.latitude,
    this.longitude,
    this.myRating,
  });

  bool get isVideo {
    if (mediaType == 'video') return true;
    final url = mediaUrl?.toLowerCase() ?? '';
    return url.contains('.mp4') || url.contains('.mov') || url.contains('.webm');
  }

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final avatarUrl = json['avatar'] as String?;
    final loc = json['location_point'] as Map<String, dynamic>?;
    return FeedPost(
      id: json['id'].toString(),
      title: json['title'] as String,
      username: user['username'] as String,
      avatarUrl: avatarUrl,
      description: json['description'] as String,
      mediaUrl: json['media_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      mediaType: json['media_type'] as String?,
      likeCount: (json['like_count'] as num).toInt(),
      avgRating: (json['avg_rating'] as num).toDouble(),
      compositeScore: (json['composite_score'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      latitude: (loc?['latitude'] as num?)?.toDouble(),
      longitude: (loc?['longitude'] as num?)?.toDouble(),
      myRating: (json['my_rating'] as num?)?.toInt(),
    );
  }
}
