import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/user_model.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';

class EmailVerificationRequiredException implements Exception {
  final String email;
  final String message;
  EmailVerificationRequiredException(this.email, this.message);
  @override
  String toString() => message;
}

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
      
      final needsVerification = data['needsVerification'] == true ||
          data['needsVerification']?.toString() == 'true' ||
          data['token'] == null;

      if (needsVerification) {
        throw EmailVerificationRequiredException(
          data['email'] as String? ?? username,
          data['message'] as String? ?? 'Email verification required',
        );
      }

      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      final apiException = ApiException.fromDioError(e);
      _handleVerificationError(apiException, username);
      throw apiException;
    } catch (e) {
      if (e is ApiException) {
        _handleVerificationError(e, username);
      }
      rethrow;
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
      
      final needsVerification = data['needsVerification'] == true ||
          data['needsVerification']?.toString() == 'true' ||
          data['token'] == null ||
          (data['message']?.toString().toLowerCase().contains('verify') ?? false);

      if (needsVerification) {
        throw EmailVerificationRequiredException(
          data['email'] as String? ?? email ?? username,
          data['message'] as String? ?? 'Email verification required',
        );
      }

      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      final apiException = ApiException.fromDioError(e);
      _handleVerificationError(apiException, email ?? username);
      throw apiException;
    } catch (e) {
      if (e is ApiException) {
        _handleVerificationError(e, email ?? username);
      }
      rethrow;
    }
  }

  void _handleVerificationError(ApiException e, String usernameOrEmail) {
    final messageLower = e.message.toLowerCase();
    final isVerify = e.statusCode == 403 || 
        messageLower.contains('verify') || 
        messageLower.contains('verified') ||
        (e.rawData is Map && (e.rawData['needsVerification'] == true || e.rawData['needsVerification']?.toString() == 'true'));
    
    if (isVerify) {
      String emailAddress = usernameOrEmail;
      if (e.rawData is Map && e.rawData['email'] != null) {
        emailAddress = e.rawData['email'] as String;
      }
      throw EmailVerificationRequiredException(
        emailAddress,
        e.message,
      );
    }
  }

  Future<UserModel> googleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        serverClientId: '1083510169013-6c5k7sk31kcdhja230qgasis4o3umkib.apps.googleusercontent.com',
      );
      
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In aborted');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      if (auth.idToken == null && auth.accessToken == null) {
        throw Exception('Failed to get authentication tokens from Google');
      }

      final response = await _api.post('/auth/google', data: {
        'idToken': auth.idToken,
        'accessToken': auth.accessToken,
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

  Future<UserModel> appleSignIn() async {
    try {
      final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await _api.post('/auth/apple', data: {
        'identityToken': credential.identityToken,
        'authorizationCode': credential.authorizationCode,
        'givenName': credential.givenName,
        'familyName': credential.familyName,
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
      throw Exception('Apple Sign-In Failed: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        serverClientId: '1083510169013-6c5k7sk31kcdhja230qgasis4o3umkib.apps.googleusercontent.com',
      );
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
    } catch (e) {
      // Ignore Google Sign-Out failures during general logout
    }
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

  Future<UserModel> verifyEmail(String email, String code) async {
    try {
      final response = await _api.post('/auth/verify-email', data: {
        'email': email.trim(),
        'code': code.trim(),
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

  Future<void> resendVerification(String email) async {
    try {
      await _api.post('/auth/resend-verification', data: {'email': email.trim()});
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> seenAnnouncement() async {
    try {
      await _api.post('/auth/seen-announcement');
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
