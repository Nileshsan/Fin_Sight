/// Types Library
/// Shared type definitions and models

// Common type aliases
typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<dynamic>;
typedef VoidCallback = void Function();
typedef ValueCallback<T> = void Function(T value);
typedef FutureVoidCallback = Future<void> Function();
typedef FutureValueCallback<T> = Future<void> Function(T value);

/// Generic API response
class GenericResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? code;

  GenericResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.code,
  });

  factory GenericResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return GenericResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
      code: json['code'] as int?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'success': success,
      'data': data != null ? toJsonT(data as T) : null,
      'message': message,
      'error': error,
      'code': code,
    };
  }
}

/// Paginated response
class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  PaginatedResponse({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final items = json['data'] as List?;
    return PaginatedResponse(
      data: items?.map((e) => fromJsonT(e)).toList() ?? [],
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'data': data.map(toJsonT).toList(),
      'page': page,
      'pageSize': pageSize,
      'total': total,
      'totalPages': totalPages,
    };
  }
}

/// Async result wrapper
sealed class AsyncResult<T> {
  const AsyncResult();
}

/// Loading state
class Loading<T> extends AsyncResult<T> {
  const Loading();
}

/// Success state
class Success<T> extends AsyncResult<T> {
  final T data;
  const Success(this.data);
}

/// Error state
class Failure<T> extends AsyncResult<T> {
  final String message;
  final dynamic error;
  const Failure(this.message, {this.error});
}

/// Result wrapper with success/failure
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory Result.success(T data) {
    return Result(
      data: data,
      isSuccess: true,
    );
  }

  factory Result.failure(String error) {
    return Result(
      error: error,
      isSuccess: false,
    );
  }

  T? getOrNull() => data;

  String? getErrorOrNull() => error;

  void fold(
    Function(T) onSuccess,
    Function(String) onFailure,
  ) {
    if (isSuccess && data != null) {
      onSuccess(data as T);
    } else if (!isSuccess && error != null) {
      onFailure(error as String);
    }
  }
}
