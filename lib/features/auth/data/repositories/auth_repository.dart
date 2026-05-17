import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/user_model.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      return user;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> register(String username, String password, {String? email}) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'username': username,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      return user;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> googleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: '604323730083-db8buapk2e3s42kdmj7v3cvaah7vsqpq.apps.googleusercontent.com',
        serverClientId: '604323730083-db8buapk2e3s42kdmj7v3cvaah7vsqpq.apps.googleusercontent.com',
      );
      
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In aborted');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final response = await _api.post('/auth/google', data: {
        'idToken': auth.idToken,
      });

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      return user;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw Exception('Google Sign-In Failed: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _api.post('/auth/forgot-password', data: {'email': email.trim()});
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _api.post('/auth/reset-password', data: {
        'email': email.trim(),
        'token': token.trim(),
        'newPassword': newPassword,
      });
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    UserModel? cachedUser;
    try {
      final token = await _storage.read(key: AppConstants.tokenKey).timeout(const Duration(seconds: 2));
      if (token == null) return null;

      // Try to return cached user first
      final userJson = await _storage.read(key: AppConstants.userKey).timeout(const Duration(seconds: 2));
      if (userJson != null) {
        cachedUser = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }

      // Refresh from server
      final response = await _api.get('/auth/me').timeout(const Duration(seconds: 5));
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      return user;
    } on ApiException catch (e) {
      // If token is actually invalid, force sign-out.
      if (e.statusCode == 401) {
        await logout();
        return null;
      }
      // For transient backend/network issues, keep local session.
      return cachedUser;
    } catch (_) {
      // For parse/network edge-cases, keep local session if available.
      return cachedUser;
    }
  }

  Future<void> updateProfile({
    required String username,
    required String avatarUrl,
    required bool hideUsername,
  }) async {
    try {
      await _api.put('/auth/profile', data: {
        'username': username.trim(),
        'avatar_url': avatarUrl.trim(),
        'hide_username': hideUsername,
      });
      // Optionally re-fetch user to cache the new data
      await getCurrentUser();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
