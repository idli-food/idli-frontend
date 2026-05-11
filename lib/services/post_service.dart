import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

  Future<({String uploadUrl, String key})> getUploadUrl(
    String fileName,
    String contentType,
  ) async {
    final url = '$_base/post/content/upload-url/';
    debugPrint('[PostService] POST $url');
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'file_name': fileName, 'content_type': contentType}),
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

  Future<void> createPost({
    required String title,
    required String description,
    required String mediaType,
    required String rawS3Key,
    required String mediaUrl,
  }) async {
    final url = '$_base/post/';
    final payload = {
      'user': 1,
      'title': title,
      'description': description,
      'media_type': mediaType,
      'raw_s3_key': rawS3Key,
      'media_url': mediaUrl,
      'thumbnail_url': mediaUrl,
      'status': 'published',
      'location': {
        'type': 'Point',
        'coordinates': [76.2673, 9.9312],
      },
    };
    debugPrint('[PostService] POST $url  payload=${jsonEncode(payload)}');
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    debugPrint('[PostService] createPost → ${res.statusCode}  body=${res.body}');
    if (res.statusCode != 201) {
      throw Exception('Failed to create post (${res.statusCode}): ${res.body}');
    }
  }
}
