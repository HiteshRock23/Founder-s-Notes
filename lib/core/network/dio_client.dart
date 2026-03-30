import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/endpoints.dart';
import '../errors/api_exception.dart';
import 'package:mobile/core/storage/token_storage.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return DioClient(tokenStorage);
});

// ── DioClient ─────────────────────────────────────────────────────────────────

/// Global callback set by AuthNotifier so the Dio interceptor can trigger
/// a force-logout without importing Riverpod into the network layer
/// (that would create a circular dependency).
typedef OnForceLogout = Future<void> Function();
OnForceLogout? _onForceLogoutCallback;

void registerForceLogoutCallback(OnForceLogout callback) {
  _onForceLogoutCallback = callback;
}

class DioClient {
  final Dio _dio;
  final TokenStorage _storage;

  /// A separate, interceptor-free Dio instance used exclusively for token
  /// refresh. This prevents recursive interceptor loops on 401.
  final Dio _refreshDio;

  /// Guards against multiple simultaneous refresh attempts.
  bool _isRefreshing = false;

  DioClient(this._storage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: Endpoints.baseUrl,
            connectTimeout:
                const Duration(milliseconds: Endpoints.connectionTimeout),
            receiveTimeout:
                const Duration(milliseconds: Endpoints.receiveTimeout),
            contentType: 'application/json',
          ),
        ),
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: Endpoints.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            contentType: 'application/json',
          ),
        ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  // ── Request: attach Bearer token ──────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ── Error: refresh on 401, then retry ─────────────────────────────────────

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = error.response?.statusCode;

    // Only attempt refresh for 401 errors that are not themselves from the
    // refresh or login endpoints (to prevent infinite loops).
    final isAuthEndpoint =
        error.requestOptions.path.contains(Endpoints.refreshToken) ||
            error.requestOptions.path.contains(Endpoints.login);

    if (statusCode == 401 && !isAuthEndpoint && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          // Retry the original request with the fresh token.
          final retryOptions = Options(
            method: error.requestOptions.method,
            headers: {
              ...error.requestOptions.headers,
              'Authorization': 'Bearer $newAccessToken',
            },
          );

          final retryResponse = await _dio.request<dynamic>(
            error.requestOptions.path,
            data: error.requestOptions.data,
            queryParameters: error.requestOptions.queryParameters,
            options: retryOptions,
          );

          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        // Refresh itself failed — force logout below.
      } finally {
        _isRefreshing = false;
      }

      // Refresh failed → clear credentials and signal the app to logout.
      await _storage.clearTokens();
      debugPrint('[DioClient] Refresh token expired. Forcing logout.');
      await _onForceLogoutCallback?.call();
    }

    handler.next(error);
  }

  // ── Token Refresh ─────────────────────────────────────────────────────────

  /// Performs the token refresh using the interceptor-free [_refreshDio].
  /// Returns the new access token string, or null if refresh fails.
  Future<String?> _refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _refreshDio.post(
        Endpoints.refreshToken,
        data: {'refresh': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['access'] as String;
      await _storage.saveAccessToken(newAccessToken);
      return newAccessToken;
    } on DioException catch (e) {
      debugPrint('[DioClient] Token refresh failed: ${e.response?.statusCode}');
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
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        message: 'The request timed out. Please check your connection.',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(
        message:
            'Cannot reach the server. Check your internet or try again later.',
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
        message =
            data['message']?.toString() ?? data['detail']?.toString();
      } else if (data is List && data.isNotEmpty) {
        message = data.first.toString();
      }

      return ApiException(
        message:
            message ?? 'Unexpected server error (status: $statusCode).',
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: 'A network error occurred. Please try again.',
    );
  }

  /// Converts Django field-error maps into a single readable string.
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
