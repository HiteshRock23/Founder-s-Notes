class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  ApiException({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException({String? message})
      : super(message: message ?? 'No Internet Connection');
}

class UnauthenticatedException extends ApiException {
  UnauthenticatedException({String? message})
      : super(
            message: message ?? 'Session expired. Please login again.',
            statusCode: 401);
}

class ValidationException extends ApiException {
  ValidationException({String? message, dynamic errors})
      : super(
            message: message ?? 'Validation failed',
            statusCode: 400,
            error: errors);
}
