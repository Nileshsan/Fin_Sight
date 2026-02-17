import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../exceptions/api_exceptions.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

/// API Service for handling all HTTP requests
class ApiService {
  final String baseUrl;
  final Logger logger;
  final StorageService storageService;

  late final Dio _dio;
  late final Dio _dioNoAuth;

  // Increased timeout to accommodate potentially long-running Django analysis
  // Set to a very large value (1 hour) while we measure full run times
  static const Duration _timeoutDuration = Duration(hours: 1);

  ApiService({
    required this.baseUrl,
    Logger? logger,
    StorageService? storageService,
  })  : logger = logger ?? Logger(),
        storageService = storageService ?? StorageService() {
    _initializeDio();
  }

  /// Initialize Dio instances
  void _initializeDio() {
    // Dio with authentication
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeoutDuration,
        receiveTimeout: _timeoutDuration,
        sendTimeout: _timeoutDuration,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Dio without authentication (for login/signup)
    _dioNoAuth = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeoutDuration,
        receiveTimeout: _timeoutDuration,
        sendTimeout: _timeoutDuration,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _addInterceptors();
  }

  /// Add request/response interceptors
  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    _dioNoAuth.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequestNoAuth,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Add Dio's verbose logger for full network visibility
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
    ));
    _dioNoAuth.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
    ));
  }

  /// Handle request with authentication
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Verbose request log
    try {
      final uri = options.uri.toString();
      logger.i('[HTTP REQUEST] ${options.method} $uri');
      logger.i('Headers: ${options.headers}');
      if (options.data != null) {
        logger.i('Request body: ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        logger.i('Query params: ${options.queryParameters}');
      }
    } catch (_) {}

    handler.next(options);
  }

  /// Handle request without authentication
  Future<void> _onRequestNoAuth(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    logger.d('${options.method} ${options.path}');
    handler.next(options);
  }

  /// Handle response
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    try {
      final uri = response.requestOptions.uri.toString();
      logger.i('[HTTP RESPONSE] ${response.statusCode} ${response.requestOptions.method} $uri');
      logger.i('Response headers: ${response.headers.map}');
      logger.i('Response body: ${response.data}');
    } catch (_) {}

    handler.next(response);
  }

  /// Handle error
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    logger.e(
      'Dio Error: ${error.message}\nRequest: ${error.requestOptions.method} ${error.requestOptions.path}',
      error: error,
      stackTrace: error.stackTrace,
    );

    try {
      logger.e('Error response data: ${error.response?.data}');
      logger.e('Error response headers: ${error.response?.headers.map}');
    } catch (_) {}

    // Handle 401 - Unauthorized
    if (error.response?.statusCode == 401) {
      // Clear tokens and trigger logout
      await storageService.clearTokens();
    }

    handler.next(error);
  }

  // ============ GET Requests ============

  /// Generic GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    bool useNoAuth = false,
  }) async {
    try {
      final dio = useNoAuth ? _dioNoAuth : _dio;
      final response = await dio.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (fromJson != null) {
          return fromJson(response.data!);
        }
        return response.data as T;
      }

      throw ServerException.from(
        response.statusCode ?? 500,
        'Failed to fetch data',
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============ POST Requests ============

  /// Generic POST request
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    bool useNoAuth = false,
  }) async {
    try {
      final dio = useNoAuth ? _dioNoAuth : _dio;
      final response = await dio.post<Map<String, dynamic>>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        if (fromJson != null) {
          return fromJson(response.data!);
        }
        return response.data as T;
      }

      throw ServerException.from(
        response.statusCode ?? 500,
        'Failed to post data',
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============ PUT Requests ============

  /// Generic PUT request
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (fromJson != null) {
          return fromJson(response.data!);
        }
        return response.data as T;
      }

      throw ServerException.from(
        response.statusCode ?? 500,
        'Failed to update data',
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============ DELETE Requests ============

  /// Generic DELETE request
  Future<void> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException.from(
          response.statusCode ?? 500,
          'Failed to delete',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============ PATCH Requests ============

  /// Generic PATCH request
  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (fromJson != null) {
          return fromJson(response.data!);
        }
        return response.data as T;
      }

      throw ServerException.from(
        response.statusCode ?? 500,
        'Failed to patch data',
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============ Helper Methods ============

  /// Handle Dio exceptions
  AppException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();

      case DioExceptionType.connectionError:
        return NetworkException.noConnection();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final message = error.response?.data?['message'] ??
            error.message ??
            'Unknown error';

        if (statusCode >= 500) {
          return ServerException.from(statusCode, message);
        } else if (statusCode == 401) {
          return UnauthorizedException();
        } else if (statusCode == 403) {
          return ForbiddenException();
        } else {
          return ClientException.from(statusCode, message);
        }

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          code: 'REQUEST_CANCELLED',
          originalException: error,
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: error.message ?? 'Unknown error occurred',
          originalException: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Bad certificate',
          code: 'BAD_CERTIFICATE',
          originalException: error,
        );

      case DioExceptionType.unknown:
        return NetworkException(
          message: 'Connection error',
          code: 'CONNECTION_ERROR',
          originalException: error,
        );
    }
  }

  /// Update authorization header
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization header
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Get Dio instance
  Dio getDio() => _dio;

  /// Get Dio instance without auth
  Dio getDioNoAuth() => _dioNoAuth;
}
