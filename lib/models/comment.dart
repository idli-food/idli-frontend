class Comment {
  final String id;
  final String username;
  final String? avatar;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.username,
    this.avatar,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        username: json['username'] as String,
        avatar: json['avatar'] as String?,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
