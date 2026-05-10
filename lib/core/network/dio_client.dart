import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/endpoints.dart';
import '../errors/api_exception.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

// ── DioClient ─────────────────────────────────────────────────────────────────

class DioClient {
  final Dio _dio;

  DioClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: Endpoints.baseUrl,
            connectTimeout:
                const Duration(milliseconds: Endpoints.connectionTimeout),
            receiveTimeout:
                const Duration(milliseconds: Endpoints.receiveTimeout),
            contentType: 'application/json',
          ),
        ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // ── 1. Firebase token injector ─────────────────────────────────────────
    // Injects "Authorization: Bearer <id_token>" before every request.
    // The token fetch is wrapped in a 5-second timeout so a slow/cold Firebase
    // SDK can never block the entire request queue indefinitely.
    // On a 401 response it force-refreshes the token and retries once.
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('[DioClient] →  ');
          try {
            final token = await _getToken()
                .timeout(const Duration(seconds: 5), onTimeout: () {
              debugPrint('[DioClient] ⚠ getIdToken() timed out after 5s — sending request without token');
              return null;
            });
            if (token != null) {
              options.headers['Authorization'] = 'Bearer ';
            }
          } catch (e) {
            debugPrint('[DioClient] ⚠ Failed to get token:  — continuing without auth header');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '[DioClient] ✓  ');
          return handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint(
              '[DioClient] ✗   — ');

          // 401: force-refresh the token and retry once
          if (error.response?.statusCode == 401) {
            debugPrint('[DioClient] 401 detected — attempting token refresh + retry');
            try {
              final newToken = await _getToken(forceRefresh: true)
                  .timeout(const Duration(seconds: 5), onTimeout: () {
                debugPrint('[DioClient] ⚠ Force-refresh timed out — giving up');
                return null;
              });
              if (newToken != null) {
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                try {
                  final response = await _dio.fetch(opts);
                  return handler.resolve(response);
                } catch (retryErr) {
                  debugPrint('[DioClient] Retry after refresh also failed: $retryErr');
                }
              }
            } catch (e) {
              debugPrint('[DioClient] Token refresh error: $e');
            }
          }
          return handler.next(error);
        },
      ),
    );

    // ── 2. Debug logger ───────────────────────────────────────────────────
    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ));
    }
  }

  /// Returns the current user's Firebase ID token, or null if not signed in.
  Future<String?> _getToken({bool forceRefresh = false}) async {
    try {
      return await FirebaseAuth.instance.currentUser
          ?.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('[DioClient] getIdToken error: $e');
      return null;
    }
  }

  // ── HTTP Methods ──────────────────────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      debugPrint('[DioClient] GET $path');
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
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
      debugPrint('[DioClient] POST $path');
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      debugPrint('[DioClient] PATCH $path');
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      debugPrint('[DioClient] DELETE $path');
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error Mapping ─────────────────────────────────────────────────────────

  ApiException _handleError(DioException e) {
    debugPrint('[DioClient] _handleError: type= status= msg=');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException(
        message: 'The request timed out. Check your connection and make sure the server is reachable.',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: 'Cannot reach the server. Check your Wi-Fi or verify the server IP in endpoints.dart.',
      );
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (statusCode == 401) return UnauthenticatedException();

      if (statusCode == 400) {
        final errorMsg = _extractDjangoErrors(data);
        return ValidationException(message: errorMsg, errors: data);
      }

      String? message;
      if (data is Map) {
        message = data['message']?.toString() ?? data['detail']?.toString();
      } else if (data is List && data.isNotEmpty) {
        message = data.first.toString();
      }

      return ApiException(
        message: message ?? 'Server error (status: $statusCode).',
        statusCode: statusCode,
      );
    }

    return ApiException(message: 'A network error occurred. Please try again.');
  }

  String _extractDjangoErrors(dynamic data) {
    if (data == null) return 'Validation failed.';
    if (data is Map) {
      final parts = <String>[];
      data.forEach((key, value) {
        String msg;
        if (value is List) {
          msg = value.map((v) => v.toString()).join(', ');
        } else {
          msg = value.toString();
        }
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
