/// API Utilities
/// Common utilities for API operations

import 'package:dio/dio.dart';

/// Build query parameters
Map<String, dynamic> buildQueryParams(Map<String, dynamic>? params) {
  if (params == null) return {};

  final filtered = <String, dynamic>{};

  params.forEach((key, value) {
    if (value != null && value != '') {
      filtered[key] = value;
    }
  });

  return filtered;
}

/// Build headers
Map<String, dynamic> buildHeaders({
  String? token,
  Map<String, dynamic>? customHeaders,
}) {
  final headers = <String, dynamic>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }

  if (customHeaders != null) {
    headers.addAll(customHeaders);
  }

  return headers;
}

/// Parse response error
String parseResponseError(Response response) {
  try {
    if (response.data is Map) {
      final message = response.data['message'] ?? response.data['error'];
      if (message != null) {
        return message.toString();
      }
    }
  } catch (e) {
    // Ignore parsing errors
  }

  return 'An error occurred';
}

/// Get error message from DioException
String getErrorMessage(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.badCertificate:
      return 'Certificate validation failed';
    case DioExceptionType.badResponse:
      return parseResponseError(exception.response!);
    case DioExceptionType.cancel:
      return 'Request cancelled';
    case DioExceptionType.connectionError:
      return 'Connection error';
    case DioExceptionType.connectionTimeout:
      return 'Connection timeout';
    case DioExceptionType.receiveTimeout:
      return 'Receive timeout';
    case DioExceptionType.sendTimeout:
      return 'Send timeout';
    case DioExceptionType.unknown:
      return 'Unknown error';
  }
}

/// Is error recoverable
bool isRecoverableError(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return true;
    default:
      return false;
  }
}
