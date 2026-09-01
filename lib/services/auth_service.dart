import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/token_storage.dart';

class AuthService {
  String get _base {
    final base = dotenv.env['API_BASE_URL'] ?? '';
    if (base.isEmpty) throw Exception('API_BASE_URL is not set in .env');
    return base;
  }

  Future<String> getOtp(String phone) async {
    final url = '$_base/auth/get-otp/';
    debugPrint('[AuthService] POST $url');
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone}),
    );
    debugPrint('[AuthService] getOtp → ${res.statusCode}  body=${res.body}');
    if (res.statusCode != 200) {
      throw Exception('Failed to send OTP (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['request_id'].toString();
  }

  Future<void> validateOtp(String otp, String requestId) async {
    final url = '$_base/auth/validate-otp/';
    debugPrint('[AuthService] POST $url');
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'otp': otp, 'request_id': requestId}),
    );
    debugPrint('[AuthService] validateOtp → ${res.statusCode}  body=${res.body}');
    if (res.statusCode != 200) {
      throw Exception('OTP verification failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> createUser(
    String phone,
    String username,
    String password,
  ) async {
    final url = '$_base/user/';
    debugPrint('[AuthService] POST $url');
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'username': username, 'password': password}),
    );
    debugPrint('[AuthService] createUser → ${res.statusCode}  body=${res.body}');
    if (res.statusCode != 201) {
      throw Exception('Failed to create account (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    await TokenStorage.save(
      access: body['access'] as String,
      refresh: body['refresh'] as String,
    );
  }

  Future<void> login(String identifier, String password) async {
    final url = '$_base/auth/login/';
    debugPrint('[AuthService] POST $url');
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    debugPrint('[AuthService] login → ${res.statusCode}  body=${res.body}');
    if (res.statusCode != 200) {
      throw Exception('Login failed (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final tokens = body['tokens'] as Map<String, dynamic>;
    await TokenStorage.save(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
  }

  Future<String> refreshToken(String refresh) async {
    final url = '$_base/auth/refresh/';
    debugPrint('[AuthService] POST $url');
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    debugPrint('[AuthService] refreshToken → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Token refresh failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final newAccess = body['access'] as String;
    final currentRefresh = await TokenStorage.getRefresh();
    await TokenStorage.save(access: newAccess, refresh: currentRefresh ?? refresh);
    return newAccess;
  }
}
