/// Error Service
/// Centralized error handling and custom error definitions

class AppError {
  final String code;
  final String message;
  final String? details;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.code,
    required this.message,
    this.details,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError(code: $code, message: $message)';
}

/// Common Error Codes
class ErrorCodes {
  // Network Errors
  static const String networkError = 'NETWORK_ERROR';
  static const String noInternet = 'NO_INTERNET';
  static const String timeout = 'TIMEOUT';
  static const String serverError = 'SERVER_ERROR';

  // Auth Errors
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String sessionExpired = 'SESSION_EXPIRED';

  // Validation Errors
  static const String validationError = 'VALIDATION_ERROR';
  static const String invalidEmail = 'INVALID_EMAIL';
  static const String invalidPassword = 'INVALID_PASSWORD';
  static const String fieldRequired = 'FIELD_REQUIRED';

  // Data Errors
  static const String notFound = 'NOT_FOUND';
  static const String alreadyExists = 'ALREADY_EXISTS';
  static const String dataError = 'DATA_ERROR';
  static const String parsingError = 'PARSING_ERROR';

  // Unknown Error
  static const String unknown = 'UNKNOWN_ERROR';
}

/// Error Messages
class ErrorMessages {
  static const Map<String, String> messages = {
    ErrorCodes.networkError: 'Network error occurred',
    ErrorCodes.noInternet: 'No internet connection',
    ErrorCodes.timeout: 'Request timeout',
    ErrorCodes.serverError: 'Server error',
    ErrorCodes.unauthorized: 'Unauthorized',
    ErrorCodes.forbidden: 'Forbidden',
    ErrorCodes.invalidCredentials: 'Invalid email or password',
    ErrorCodes.tokenExpired: 'Token expired',
    ErrorCodes.sessionExpired: 'Session expired',
    ErrorCodes.validationError: 'Validation error',
    ErrorCodes.invalidEmail: 'Invalid email address',
    ErrorCodes.invalidPassword: 'Invalid password',
    ErrorCodes.fieldRequired: 'This field is required',
    ErrorCodes.notFound: 'Not found',
    ErrorCodes.alreadyExists: 'Already exists',
    ErrorCodes.dataError: 'Data error',
    ErrorCodes.parsingError: 'Parsing error',
    ErrorCodes.unknown: 'Unknown error occurred',
  };

  static String getMessageForCode(String code) {
    return messages[code] ?? 'An error occurred';
  }
}

/// Error Service
class ErrorService {
  /// Create app error from exception
  static AppError createFromException(
    dynamic exception, {
    String? customMessage,
  }) {
    if (exception is AppError) {
      return exception;
    }

    return AppError(
      code: ErrorCodes.unknown,
      message: customMessage ?? exception.toString(),
      originalError: exception,
    );
  }

  /// Parse API error response
  static AppError parseApiError(dynamic response) {
    if (response is Map<String, dynamic>) {
      final code = response['code'] as String?;
      final message = response['message'] as String?;
      final details = response['details'] as String?;

      return AppError(
        code: code ?? ErrorCodes.serverError,
        message: message ?? ErrorMessages.getMessageForCode(code ?? ErrorCodes.serverError),
        details: details,
      );
    }

    return AppError(
      code: ErrorCodes.unknown,
      message: 'An error occurred',
    );
  }

  /// Get user-friendly error message
  static String getUserMessage(AppError error) {
    return error.message.isNotEmpty
        ? error.message
        : ErrorMessages.getMessageForCode(error.code);
  }

  /// Check if error is recoverable
  static bool isRecoverable(AppError error) {
    final nonRecoverableErrors = [
      ErrorCodes.unauthorized,
      ErrorCodes.forbidden,
    ];

    return !nonRecoverableErrors.contains(error.code);
  }

  /// Check if error is network-related
  static bool isNetworkError(AppError error) {
    final networkErrors = [
      ErrorCodes.networkError,
      ErrorCodes.noInternet,
      ErrorCodes.timeout,
    ];

    return networkErrors.contains(error.code);
  }
}
