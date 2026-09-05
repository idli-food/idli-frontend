import 'feed_post.dart';

class SavedPost {
  final String id;
  final String description;
  final String username;
  final String? avatarUrl;
  final String? thumbnailUrl;
  final String? mediaUrl;
  final String? mediaType;
  final double avgRating;
  final double compositeScore;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;

  const SavedPost({
    required this.id,
    required this.description,
    required this.username,
    this.avatarUrl,
    this.thumbnailUrl,
    this.mediaUrl,
    this.mediaType,
    required this.avgRating,
    required this.compositeScore,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
    this.isSaved = true,
    required this.createdAt,
  });

  factory SavedPost.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final mediaList = json['media'] as List<dynamic>?;
    final firstMedia = (mediaList != null && mediaList.isNotEmpty)
        ? mediaList.first as Map<String, dynamic>
        : null;
    return SavedPost(
      id: json['id'].toString(),
      description: (json['description'] as String?) ?? '',
      username: user['username'] as String,
      avatarUrl: json['avatar'] as String?,
      thumbnailUrl:
          (firstMedia?['thumbnail_url'] ?? json['thumbnail_url']) as String?,
      mediaUrl: (firstMedia?['media_url'] ?? json['media_url']) as String?,
      mediaType: (firstMedia?['content_type'] ?? json['media_type']) as String?,
      avgRating: (json['avg_rating'] as num).toDouble(),
      compositeScore: (json['composite_score'] as num?)?.toDouble() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  FeedPost toFeedPost() => FeedPost(
        id: id,
        description: description,
        username: username,
        avatarUrl: avatarUrl,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        likeCount: likeCount,
        commentCount: commentCount,
        avgRating: avgRating,
        compositeScore: compositeScore,
        createdAt: createdAt,
        isLiked: isLiked,
        isSaved: isSaved,
      );
}
