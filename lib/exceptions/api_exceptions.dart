/// API Exception classes for handling network and API errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

/// API Request Exception
class ApiException extends AppException {
  ApiException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );

  factory ApiException.fromDio(dynamic error) {
    if (error is String) {
      return ApiException(message: error);
    }
    return ApiException(
      message: 'API Error: ${error.toString()}',
      originalException: error,
    );
  }
}

/// Network Connection Exception
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );

  factory NetworkException.noConnection() {
    return NetworkException(
      message: 'No internet connection',
      code: 'NO_CONNECTION',
    );
  }

  factory NetworkException.timeout() {
    return NetworkException(
      message: 'Request timeout',
      code: 'TIMEOUT',
    );
  }
}

/// Server Error Exception (5xx)
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'SERVER_ERROR',
    originalException: originalException,
  );

  factory ServerException.from(int statusCode, String? message) {
    return ServerException(
      message: message ?? 'Server error (HTTP $statusCode)',
      statusCode: statusCode,
      code: 'HTTP_$statusCode',
    );
  }
}

/// Client Error Exception (4xx)
class ClientException extends AppException {
  final int? statusCode;

  ClientException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'CLIENT_ERROR',
    originalException: originalException,
  );

  factory ClientException.from(int statusCode, String? message) {
    final String defaultMessage;
    switch (statusCode) {
      case 400:
        defaultMessage = 'Bad request';
        break;
      case 401:
        defaultMessage = 'Unauthorized - Please login again';
        break;
      case 403:
        defaultMessage = 'Forbidden - You don\'t have permission';
        break;
      case 404:
        defaultMessage = 'Not found';
        break;
      default:
        defaultMessage = 'Client error (HTTP $statusCode)';
    }
    return ClientException(
      message: message ?? defaultMessage,
      statusCode: statusCode,
      code: 'HTTP_$statusCode',
    );
  }
}

/// Unauthorized Exception (401)
class UnauthorizedException extends ClientException {
  UnauthorizedException({
    String message = 'Unauthorized - Please login again',
    dynamic originalException,
  }) : super(
    message: message,
    statusCode: 401,
    code: 'UNAUTHORIZED',
    originalException: originalException,
  );
}

/// Forbidden Exception (403)
class ForbiddenException extends ClientException {
  ForbiddenException({
    String message = 'Forbidden - You don\'t have permission',
    dynamic originalException,
  }) : super(
    message: message,
    statusCode: 403,
    code: 'FORBIDDEN',
    originalException: originalException,
  );
}

/// Parsing Exception
class ParsingException extends AppException {
  ParsingException({
    String message = 'Failed to parse response',
    dynamic originalException,
  }) : super(
    message: message,
    code: 'PARSING_ERROR',
    originalException: originalException,
  );
}

/// Cache Exception
class CacheException extends AppException {
  CacheException({
    required String message,
    dynamic originalException,
  }) : super(
    message: message,
    code: 'CACHE_ERROR',
    originalException: originalException,
  );
}

/// Validation Exception
class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException({
    required String message,
    this.errors,
    dynamic originalException,
  }) : super(
    message: message,
    code: 'VALIDATION_ERROR',
    originalException: originalException,
  );
}
