import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/comment.dart';
import '../models/feed_post.dart';
import '../models/hotel.dart';
import '../models/saved_post.dart';
import '../models/saved_thumb.dart';
import '../utils/token_storage.dart';
import 'auth_service.dart';

class PostService {
  String get _base {
    final base = dotenv.env['API_BASE_URL'] ?? '';
    if (base.isEmpty) {
      throw Exception(
        'API_BASE_URL is not set in .env — set it to your backend URL (e.g. http://192.168.1.x:8000)',
      );
    }
    return base;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getAccess();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _getWithRefresh(Uri uri, Map<String, String> headers) async {
    var res = await http.get(uri, headers: headers);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final refresh = await TokenStorage.getRefresh();
      if (refresh != null) {
        final newAccess = await _attemptRefresh(refresh);
        final retryHeaders = Map<String, String>.from(headers)
          ..['Authorization'] = 'Bearer $newAccess';
        res = await http.get(uri, headers: retryHeaders);
      } else {
        throw Exception('Session expired. Please log in again.');
      }
    }
    return res;
  }

  Future<http.Response> _postWithRefresh(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    var res = await http.post(uri, headers: headers, body: body);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final refresh = await TokenStorage.getRefresh();
      if (refresh != null) {
        final newAccess = await _attemptRefresh(refresh);
        final retryHeaders = Map<String, String>.from(headers)
          ..['Authorization'] = 'Bearer $newAccess';
        res = await http.post(uri, headers: retryHeaders, body: body);
      } else {
        throw Exception('Session expired. Please log in again.');
      }
    }
    return res;
  }

  Future<http.Response> _deleteWithRefresh(
    Uri uri,
    Map<String, String> headers,
  ) async {
    var res = await http.delete(uri, headers: headers);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final refresh = await TokenStorage.getRefresh();
      if (refresh != null) {
        final newAccess = await _attemptRefresh(refresh);
        final retryHeaders = Map<String, String>.from(headers)
          ..['Authorization'] = 'Bearer $newAccess';
        res = await http.delete(uri, headers: retryHeaders);
      } else {
        throw Exception('Session expired. Please log in again.');
      }
    }
    return res;
  }

  Future<http.Response> _patchWithRefresh(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    var res = await http.patch(uri, headers: headers, body: body);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final refresh = await TokenStorage.getRefresh();
      if (refresh != null) {
        final newAccess = await _attemptRefresh(refresh);
        final retryHeaders = Map<String, String>.from(headers)
          ..['Authorization'] = 'Bearer $newAccess';
        res = await http.patch(uri, headers: retryHeaders, body: body);
      } else {
        throw Exception('Session expired. Please log in again.');
      }
    }
    return res;
  }

  Future<String> _attemptRefresh(String refresh) async {
    try {
      return await AuthService().refreshToken(refresh);
    } catch (e) {
      debugPrint('[PostService] token refresh failed: $e');
      await TokenStorage.clear();
      throw Exception('Session expired. Please log in again.');
    }
  }

  Future<List<FeedPost>> getFeed({
    required double lat,
    required double lon,
    double radius = 10,
  }) async {
    final uri = Uri.parse('$_base/feed/').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'radius': radius.toString(),
    });
    debugPrint('[PostService] GET $uri');
    final headers = await _authHeaders();
    final res = await _getWithRefresh(uri, headers);
    debugPrint('[PostService] getFeed → ${res.statusCode}  body=${res.body.substring(0, res.body.length.clamp(0, 500))}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load feed (${res.statusCode}): ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    final seen = <String>{};
    return list
        .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
        .where((p) => seen.add(p.id))
        .toList();
  }

  Future<({String uploadUrl, String key})> getUploadUrl(
    String fileName,
    String contentType,
  ) async {
    final url = '$_base/post/content/upload-url/';
    debugPrint('[PostService] POST $url');
    final headers = await _authHeaders();
    final res = await _postWithRefresh(
      Uri.parse(url),
      headers,
      jsonEncode({'file_name': fileName, 'content_type': contentType}),
    );
    debugPrint('[PostService] getUploadUrl → ${res.statusCode}  body=${res.body}');
    if (res.statusCode != 200) {
      throw Exception('Failed to get upload URL (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return (
      uploadUrl: data['upload_url'] as String,
      key: data['key'] as String,
    );
  }

  Future<void> uploadToS3(
    String uploadUrl,
    File file,
    String contentType,
  ) async {
    debugPrint('[PostService] PUT S3  fileSize=${await file.length()} bytes');
    final bytes = await file.readAsBytes();
    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    debugPrint('[PostService] uploadToS3 → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('S3 upload failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<List<Hotel>> getHotels() async {
    final uri = Uri.parse('$_base/hotel/list/');
    debugPrint('[PostService] GET $uri');
    final headers = await _authHeaders();
    final res = await _getWithRefresh(uri, headers);
    debugPrint('[PostService] getHotels → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load hotels (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => Hotel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPost({
    required String description,
    required String mediaType,
    required String rawS3Key,
    required int hotelId,
    required List<Map<String, dynamic>> ratings,
  }) async {
    final url = '$_base/post/';
    final payload = <String, dynamic>{
      'hotel': hotelId,
      'description': description,
      'status': 'published',
      'ratings': ratings,
      'media': [
        {
          'content_type': mediaType,
          'category': mediaType == 'video' ? 'video' : 'photos',
          'position': 0,
          'media_key': rawS3Key,
        },
      ],
    };
    debugPrint('[PostService] POST $url  payload=${jsonEncode(payload)}');
    final headers = await _authHeaders();
    final res = await _postWithRefresh(
      Uri.parse(url),
      headers,
      jsonEncode(payload),
    );
    debugPrint('[PostService] createPost → ${res.statusCode}  body=${res.body}');
    if (res.statusCode != 201) {
      throw Exception('Failed to create post (${res.statusCode}): ${res.body}');
    }
  }

  Future<List<FeedPost>> getExploreFeed({
    required double lat,
    required double lon,
    double radius = 10,
    String? query,
  }) async {
    final params = {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'radius': radius.toString(),
      'view': 'feed',
    };
    final q = query?.trim() ?? '';
    if (q.isNotEmpty) params['q'] = q;
    final uri =
        Uri.parse('$_base/feed/explore/').replace(queryParameters: params);
    debugPrint('[PostService] GET $uri');
    final headers = await _authHeaders();
    final res = await _getWithRefresh(uri, headers);
    debugPrint('[PostService] getExploreFeed → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load explore feed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map) {
      list = (decoded['data'] ?? decoded['results'] ?? <dynamic>[]) as List<dynamic>;
    } else {
      list = [];
    }
    final seen = <String>{};
    return list
        .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
        .where((p) => seen.add(p.id))
        .toList();
  }

  Future<List<SavedThumb>> getSavedThumbnails() async {
    final uri = Uri.parse('$_base/post/saved/me/');
    debugPrint('[PostService] GET $uri');
    final headers = await _authHeaders();
    final res = await _getWithRefresh(uri, headers);
    debugPrint('[PostService] getSavedThumbnails → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load saved posts (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => SavedThumb.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SavedPost>> getSavedFeed() async {
    final uri = Uri.parse('$_base/post/saved/me/')
        .replace(queryParameters: {'view': 'feed'});
    debugPrint('[PostService] GET $uri');
    final headers = await _authHeaders();
    final res = await _getWithRefresh(uri, headers);
    debugPrint('[PostService] getSavedFeed → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load saved feed (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => SavedPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Comment>> getComments(String postId) async {
    final uri = Uri.parse('$_base/post/$postId/comment/');
    debugPrint('[PostService] GET $uri');
    final headers = await _authHeaders();
    final res = await _getWithRefresh(uri, headers);
    debugPrint('[PostService] getComments → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load comments (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> likePost(String postId) async {
    final url = '$_base/post/$postId/like/';
    debugPrint('[PostService] POST $url');
    final headers = await _authHeaders();
    final res = await _postWithRefresh(Uri.parse(url), headers, '');
    debugPrint('[PostService] likePost → ${res.statusCode}');
    if (res.statusCode != 201) {
      throw Exception('Like failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> unlikePost(String postId) async {
    final url = '$_base/post/$postId/like/';
    debugPrint('[PostService] DELETE $url');
    final headers = await _authHeaders();
    final res = await _deleteWithRefresh(Uri.parse(url), headers);
    debugPrint('[PostService] unlikePost → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Unlike failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> savePost(String postId) async {
    final url = '$_base/post/$postId/save/';
    debugPrint('[PostService] POST $url');
    final headers = await _authHeaders();
    final res = await _postWithRefresh(Uri.parse(url), headers, '');
    debugPrint('[PostService] savePost → ${res.statusCode}');
    if (res.statusCode != 201) {
      throw Exception('Save failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> unsavePost(String postId) async {
    final url = '$_base/post/$postId/save/';
    debugPrint('[PostService] DELETE $url');
    final headers = await _authHeaders();
    final res = await _deleteWithRefresh(Uri.parse(url), headers);
    debugPrint('[PostService] unsavePost → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Unsave failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> unratePost(String postId) async {
    final url = '$_base/post/$postId/rate/';
    debugPrint('[PostService] DELETE $url');
    final headers = await _authHeaders();
    final res = await _deleteWithRefresh(Uri.parse(url), headers);
    debugPrint('[PostService] unratePost → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Unrate failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> addComment(String postId, String content) async {
    final url = '$_base/post/$postId/comment/';
    debugPrint('[PostService] POST $url');
    final headers = await _authHeaders();
    final res = await _postWithRefresh(
      Uri.parse(url),
      headers,
      jsonEncode({'content': content}),
    );
    debugPrint('[PostService] addComment → ${res.statusCode}');
    if (res.statusCode != 201) {
      throw Exception('Comment failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final url = '$_base/post/$postId/comment/$commentId/';
    debugPrint('[PostService] DELETE $url');
    final headers = await _authHeaders();
    final res = await _deleteWithRefresh(Uri.parse(url), headers);
    debugPrint('[PostService] deleteComment → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Delete comment failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> updatePost(
    String postId, {
    String? description,
  }) async {
    final url = '$_base/post/$postId/';
    final payload = <String, dynamic>{
      if (description != null) 'description': description,
    };
    debugPrint('[PostService] PATCH $url  payload=${jsonEncode(payload)}');
    final headers = await _authHeaders();
    final res = await _patchWithRefresh(
      Uri.parse(url),
      headers,
      jsonEncode(payload),
    );
    debugPrint('[PostService] updatePost → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to update post (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> deletePost(String postId) async {
    final url = '$_base/post/$postId/';
    debugPrint('[PostService] DELETE $url');
    final headers = await _authHeaders();
    final res = await _deleteWithRefresh(Uri.parse(url), headers);
    debugPrint('[PostService] deletePost → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete post (${res.statusCode}): ${res.body}');
    }
  }
}
