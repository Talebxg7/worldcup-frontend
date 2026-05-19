import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      // Auth interceptor - attach token to every request
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final path = e.requestOptions.path;
          // Only clear session when /auth/me says token is invalid/expired.
          // Other 401s (e.g. room feature while backend/auth state mismatched)
          // should not force a global logout loop.
          if (e.response?.statusCode == 401 && path == '/auth/me') {
            await _storage.delete(key: AppConstants.tokenKey);
            await _storage.delete(key: AppConstants.userKey);
          }
          return handler.next(e);
        },
      ),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  // Generic GET
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  // Generic POST
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // Generic PUT
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // Generic DELETE
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

// Custom exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic rawData;

  ApiException({required this.message, this.statusCode, this.rawData});

  factory ApiException.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Connection timed out. Check your internet.');
      case DioExceptionType.connectionError:
        return ApiException(message: 'No internet connection.');
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        String msg;
        if (data is Map && data['message'] != null) {
          msg = '${data['message']}';
        } else if (data is String && data.trim().isNotEmpty) {
          msg = data;
        } else {
          msg = 'Server error occurred.';
        }
        return ApiException(
          message: msg, 
          statusCode: e.response?.statusCode,
          rawData: data,
        );
      default:
        return ApiException(message: 'Something went wrong. Try again.');
    }
  }

  @override
  String toString() => message;
}
