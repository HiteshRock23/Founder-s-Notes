import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/endpoints.dart';
import '../errors/api_exception.dart';
import 'package:mobile/core/storage/token_storage.dart';

// Providers
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return DioClient(tokenStorage);
});

class DioClient {
  final Dio _dio;
  final TokenStorage _storage;

  DioClient(this._storage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: Endpoints.baseUrl,
            connectTimeout: const Duration(milliseconds: Endpoints.connectionTimeout),
            receiveTimeout: const Duration(milliseconds: Endpoints.receiveTimeout),
            contentType: 'application/json',
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Future: Implement refresh token logic here
          }
          return handler.next(e);
        },
      ),
    );

    // Production-ready logging
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      compact: true,
    ));
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: 'Request timed out');
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (statusCode == 401) return UnauthenticatedException();

      if (statusCode == 400) {
        // Extract human-readable message from Django validation errors.
        // Django returns: {'field': ['error msg']} or {'non_field_errors': [...]}
        final errorMsg = _extractDjangoErrors(data);
        return ValidationException(
          message: errorMsg,
          errors: data,
        );
      }

      return ApiException(
        message: data?['message'] ?? data?['detail'] ?? 'Unexpected error occurred',
        statusCode: statusCode,
      );
    }

    return ApiException(message: 'Network error: ${e.message}');
  }

  /// Converts Django's field-error map into a single readable string.
  /// e.g. {'url': ['Enter a valid URL.']} → 'url: Enter a valid URL.'
  String _extractDjangoErrors(dynamic data) {
    if (data == null) return 'Validation failed';
    if (data is Map) {
      final parts = <String>[];
      data.forEach((key, value) {
        String msg;
        if (value is List) {
          msg = value.map((v) => v.toString()).join(', ');
        } else {
          msg = value.toString();
        }
        // Hide internal field names that mean nothing to the user.
        if (key == 'non_field_errors' || key == 'detail') {
          parts.add(msg);
        } else {
          parts.add('$key: $msg');
        }
      });
      return parts.join('\n');
    }
    return data.toString();
  }
}
