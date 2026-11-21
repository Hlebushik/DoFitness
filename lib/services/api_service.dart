import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/settings_controller.dart';
import '../models/exercise_model.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthResponse {
  final String accessToken;
  final UserModel user;

  AuthResponse({required this.accessToken, required this.user});
}

class ApiService {
  SettingsController get _settings => Get.find<SettingsController>();

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(_settings.httpBaseUrl);
    return base.replace(path: path, queryParameters: queryParams);
  }

  Map<String, String> _headers([String? token]) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final bodyText = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> data =
        bodyText.isNotEmpty ? jsonDecode(bodyText) as Map<String, dynamic> : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == 401) {
      throw ApiException('invalid_credentials'.tr, statusCode: 401);
    }
    if (response.statusCode == 409) {
      throw ApiException('account_exists'.tr, statusCode: 409);
    }

    final detail =
        data['detail']?.toString() ?? '${'server_error'.tr} (${response.statusCode})';
    throw ApiException(detail, statusCode: response.statusCode);
  }

  Future<T> _guarded<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 6));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('server_timeout'.tr);
    } on SocketException {
      throw ApiException('server_unreachable'.tr);
    } catch (_) {
      throw ApiException('network_error'.tr);
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) {
    return _guarded(() async {
      final res = await http.post(
        _uri('/api/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = await _handleResponse(res);
      return AuthResponse(
        accessToken: data['access_token'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    });
  }

  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    String preferredLocale = 'uk',
  }) {
    return _guarded(() async {
      final res = await http.post(
        _uri('/api/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
          'preferred_locale': preferredLocale,
        }),
      );
      final data = await _handleResponse(res);
      return AuthResponse(
        accessToken: data['access_token'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    });
  }

  Future<UserModel> getMe(String token) {
    return _guarded(() async {
      final res = await http.get(
        _uri('/api/auth/me'),
        headers: _headers(token),
      );
      final data = await _handleResponse(res);
      return UserModel.fromJson(data);
    });
  }

  Future<UserModel> updatePreferences({
    required String token,
    String? username,
    String? preferredLocale,
  }) {
    return _guarded(() async {
      final res = await http.patch(
        _uri('/api/auth/preferences'),
        headers: _headers(token),
        body: jsonEncode({
          if (username != null) 'username': username,
          if (preferredLocale != null) 'preferred_locale': preferredLocale,
        }),
      );
      final data = await _handleResponse(res);
      return UserModel.fromJson(data);
    });
  }

  Future<List<ExerciseModel>> getExercises({
    String? token,
    String? category,
    bool favoritesOnly = false,
    String lang = 'uk',
  }) {
    return _guarded(() async {
      final params = <String, String>{
        'lang': lang,
        if (category != null) 'category': category,
        if (favoritesOnly) 'favorites_only': 'true',
      };
      final res = await http.get(
        _uri('/api/exercises', params),
        headers: _headers(token),
      );
      final data = await _handleResponse(res);
      final list = data['exercises'] as List<dynamic>;
      return list
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<bool> toggleFavorite({
    required String token,
    required String slug,
  }) {
    return _guarded(() async {
      final res = await http.post(
        _uri('/api/exercises/$slug/favorite'),
        headers: _headers(token),
      );
      final data = await _handleResponse(res);
      return data['is_favorite'] as bool;
    });
  }

  Future<void> saveWorkout({
    required String token,
    required String exerciseSlug,
    required int durationSeconds,
    required int repsCount,
  }) {
    return _guarded(() async {
      final res = await http.post(
        _uri('/api/workouts'),
        headers: _headers(token),
        body: jsonEncode({
          'exercise_slug': exerciseSlug,
          'duration_seconds': durationSeconds,
          'reps_count': repsCount,
        }),
      );
      await _handleResponse(res);
    });
  }
}