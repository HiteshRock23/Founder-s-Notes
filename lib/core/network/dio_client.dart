import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/endpoints.dart';
import '../errors/api_exception.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

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
    // Production-ready logging
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
