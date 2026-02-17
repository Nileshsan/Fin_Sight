/// Error Handler Utilities
/// Centralized error handling utilities

import 'package:dio/dio.dart';
import '../services/errors_service.dart';

/// Handle API error
AppError handleApiError(dynamic error, {String? customMessage}) {
  if (error is AppError) {
    return error;
  }

  if (error is DioException) {
    return handleDioError(error, customMessage: customMessage);
  }

  if (error is Exception) {
    return AppError(
      code: ErrorCodes.unknown,
      message: customMessage ?? error.toString(),
      originalError: error,
    );
  }

  return AppError(
    code: ErrorCodes.unknown,
    message: customMessage ?? 'An unknown error occurred',
    originalError: error,
  );
}

/// Handle Dio exception
AppError handleDioError(DioException error, {String? customMessage}) {
  String code;
  String message;

  switch (error.type) {
    case DioExceptionType.badCertificate:
      code = ErrorCodes.networkError;
      message = 'Certificate validation failed';
      break;

    case DioExceptionType.badResponse:
      if (error.response?.statusCode == 401) {
        code = ErrorCodes.unauthorized;
        message = 'Unauthorized access';
      } else if (error.response?.statusCode == 403) {
        code = ErrorCodes.forbidden;
        message = 'Access forbidden';
      } else if (error.response?.statusCode == 404) {
        code = ErrorCodes.notFound;
        message = 'Resource not found';
      } else {
        code = ErrorCodes.serverError;
        message = 'Server error';
      }
      break;

    case DioExceptionType.cancel:
      code = ErrorCodes.networkError;
      message = 'Request cancelled';
      break;

    case DioExceptionType.connectionError:
      code = ErrorCodes.noInternet;
      message = 'Connection error';
      break;

    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      code = ErrorCodes.timeout;
      message = 'Request timeout';
      break;

    case DioExceptionType.unknown:
      code = ErrorCodes.unknown;
      message = 'Unknown error';
      break;
  }

  return AppError(
    code: code,
    message: customMessage ?? message,
    details: error.message,
    originalError: error,
  );
}

/// Log error details
void logError(
  AppError error, {
  String? tag,
  bool withStackTrace = false,
}) {
  final prefix = tag != null ? '[$tag] ' : '';
  print(
    '$prefix${error.code}: ${error.message}${error.details != null ? '\n${error.details}' : ''}',
  );

  if (withStackTrace && error.stackTrace != null) {
    print(error.stackTrace);
  }
}

/// Show user-friendly error message
String getUserErrorMessage(AppError error) {
  return ErrorService.getUserMessage(error);
}
