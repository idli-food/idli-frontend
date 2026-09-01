import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../utils/token_storage.dart';
import 'auth_service.dart';

class ProfileService {
  String get _base {
    final base = dotenv.env['API_BASE_URL'] ?? '';
    if (base.isEmpty) throw Exception('API_BASE_URL is not set in .env');
    return base;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getAccess();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String> _attemptRefresh(String refresh) async {
    try {
      return await AuthService().refreshToken(refresh);
    } catch (e) {
      debugPrint('[ProfileService] token refresh failed: $e');
      await TokenStorage.clear();
      throw Exception('Session expired. Please log in again.');
    }
  }

  Future<UserDetails> getUserDetails() async {
    final uri = Uri.parse('$_base/user/me/details/');
    debugPrint('[ProfileService] GET $uri');
    final headers = await _authHeaders();
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

    debugPrint('[ProfileService] getUserDetails → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load user details (${res.statusCode}): ${res.body}');
    }
    return UserDetails.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<UserProfile> getProfile() async {
    final uri = Uri.parse('$_base/accounts/profile/');
    debugPrint('[ProfileService] GET $uri');
    final headers = await _authHeaders();
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

    debugPrint('[ProfileService] getProfile → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load profile (${res.statusCode}): ${res.body}');
    }
    return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<({String uploadUrl, String key})> getAvatarUploadUrl(
    String fileName,
    String contentType,
  ) async {
    final uri = Uri.parse('$_base/accounts/avatar-upload-url/');
    debugPrint('[ProfileService] POST $uri');
    final headers = await _authHeaders();
    final body = jsonEncode({'file_name': fileName, 'content_type': contentType});
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

    debugPrint('[ProfileService] getAvatarUploadUrl → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to get avatar upload URL (${res.statusCode}): ${res.body}');
    }
    final data = (jsonDecode(res.body)['data'] as Map<String, dynamic>);
    return (
      uploadUrl: data['upload_url'] as String,
      key: data['key'] as String,
    );
  }

  Future<void> uploadAvatarToS3(String uploadUrl, File file, String contentType) async {
    final bytes = await file.readAsBytes();
    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    debugPrint('[ProfileService] uploadAvatarToS3 → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Avatar S3 upload failed (${res.statusCode})');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? dob,
    String? diet,
    String? foodPreference,
    String? avatar,
    double? lat,
    double? lon,
  }) async {
    final uri = Uri.parse('$_base/accounts/profile/complete/');
    debugPrint('[ProfileService] PATCH $uri');
    final headers = await _authHeaders();
    final payload = <String, dynamic>{
      if (name != null && name.isNotEmpty) 'name': name,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      if (dob != null) 'dob': dob,
      if (diet != null) 'diet': diet,
      if (foodPreference != null && foodPreference.isNotEmpty) 'food_preference': foodPreference,
      if (avatar != null) 'avatar': avatar,
      if (lat != null && lon != null) ...{'lat': lat, 'lon': lon},
    };
    final body = jsonEncode(payload);
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

    debugPrint('[ProfileService] updateProfile → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Failed to update profile (${res.statusCode}): ${res.body}');
    }
  }
}
