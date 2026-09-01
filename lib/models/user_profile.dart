class UserDetails {
  final String username;
  final String name;
  final String? avatar;
  final String bio;
  final String? dob;
  final String? diet;
  final String? foodPreference;
  final double? latitude;
  final double? longitude;

  const UserDetails({
    required this.username,
    required this.name,
    this.avatar,
    required this.bio,
    this.dob,
    this.diet,
    this.foodPreference,
    this.latitude,
    this.longitude,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    double? lat, lon;
    final loc = json['location'] as String?;
    if (loc != null) {
      final match = RegExp(r'POINT \(([^ ]+) ([^)]+)\)').firstMatch(loc);
      if (match != null) {
        lon = double.tryParse(match.group(1)!);
        lat = double.tryParse(match.group(2)!);
      }
    }
    return UserDetails(
      username: json['username'] as String,
      name: (json['name'] as String?) ?? '',
      avatar: json['avatar'] as String?,
      bio: (json['bio'] as String?) ?? '',
      dob: json['dob'] as String?,
      diet: json['diet'] as String?,
      foodPreference: json['food_preference'] as String?,
      latitude: lat,
      longitude: lon,
    );
  }
}

class ProfilePost {
  final String thumbnailUrl;
  const ProfilePost({required this.thumbnailUrl});

  factory ProfilePost.fromJson(Map<String, dynamic> json) =>
      ProfilePost(thumbnailUrl: json['thumbnail_url'] as String);
}

class UserProfile {
  final String username;
  final String name;
  final String? avatar;
  final String bio;
  final int totalPost;
  final int totalLikes;
  final int totalStars;
  final int totalRating;
  final bool isVerified;
  final int completionPercentage;
  final List<String> incompleteFields;
  final bool isProfileComplete;
  final List<ProfilePost> posts;

  const UserProfile({
    required this.username,
    required this.name,
    this.avatar,
    required this.bio,
    required this.totalPost,
    required this.totalLikes,
    required this.totalStars,
    required this.totalRating,
    required this.isVerified,
    required this.completionPercentage,
    required this.incompleteFields,
    required this.isProfileComplete,
    required this.posts,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        username: json['username'] as String,
        name: (json['name'] as String?) ?? '',
        avatar: json['avatar'] as String?,
        bio: (json['bio'] as String?) ?? '',
        totalPost: (json['total_post'] as num).toInt(),
        totalLikes: (json['total_likes'] as num).toInt(),
        totalStars: (json['total_stars'] as num).toInt(),
        totalRating: (json['total_rating'] as num).toInt(),
        isVerified: (json['is_verified'] as bool?) ?? false,
        completionPercentage: (json['completion_percentage'] as num).toInt(),
        incompleteFields:
            ((json['incomplete_fields'] as List<dynamic>?) ?? []).cast<String>(),
        isProfileComplete: (json['is_profile_complete'] as bool?) ?? false,
        posts: ((json['posts'] as List<dynamic>?) ?? [])
            .map((e) => ProfilePost.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
