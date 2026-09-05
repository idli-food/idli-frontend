class PostRating {
  final String category; // 'food' | 'service' | 'cleanliness' | 'value'
  final int score;
  final String review;

  const PostRating({
    required this.category,
    required this.score,
    required this.review,
  });

  factory PostRating.fromJson(Map<String, dynamic> json) => PostRating(
        category: json['category'] as String,
        score: (json['score'] as num).toInt(),
        review: (json['review'] as String?) ?? '',
      );
}

class FeedPost {
  final String id;
  final String title;
  final String username;
  final String? avatarUrl;
  final String description;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? hotelName;
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
  final bool isMine;
  final List<PostRating> ratings;

  const FeedPost({
    required this.id,
    required this.title,
    required this.username,
    this.avatarUrl,
    required this.description,
    this.mediaUrl,
    this.thumbnailUrl,
    this.hotelName,
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
    this.isMine = false,
    this.ratings = const [],
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
    final coordinates = loc?['coordinates'] as List<dynamic>?;
    final mediaList = json['media'] as List<dynamic>?;
    final firstMedia = (mediaList != null && mediaList.isNotEmpty)
        ? mediaList.first as Map<String, dynamic>
        : null;
    return FeedPost(
      id: json['id'].toString(),
      title: json['title'] as String,
      username: user['username'] as String,
      avatarUrl: avatarUrl,
      description: json['description'] as String,
      mediaUrl: (firstMedia?['media_url'] ?? json['media_url']) as String?,
      thumbnailUrl:
          (firstMedia?['thumbnail_url'] ?? json['thumbnail_url']) as String?,
      hotelName: json['hotel_name'] as String?,
      mediaType: (firstMedia?['content_type'] ?? json['media_type']) as String?,
      likeCount: (json['like_count'] as num).toInt(),
      avgRating: (json['avg_rating'] as num).toDouble(),
      compositeScore: (json['composite_score'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      latitude: (coordinates != null && coordinates.length > 1)
          ? (coordinates[1] as num).toDouble()
          : null,
      longitude: (coordinates != null && coordinates.isNotEmpty)
          ? (coordinates[0] as num).toDouble()
          : null,
      isMine: json['is_mine'] as bool? ?? false,
      ratings: (json['ratings'] as List<dynamic>?)
              ?.map((e) => PostRating.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
