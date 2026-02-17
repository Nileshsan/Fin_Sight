/// Generic API Response Model
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? code;
  final int? statusCode;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.code,
    this.statusCode,
    this.error,
  });

  /// Factory constructor for successful response
  factory ApiResponse.success({
    required T data,
    String? message,
    int statusCode = 200,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? 'Success',
      statusCode: statusCode,
    );
  }

  /// Factory constructor for error response
  factory ApiResponse.error({
    required String message,
    String? code,
    int statusCode = 500,
    dynamic error,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      code: code,
      statusCode: statusCode,
      error: error,
    );
  }

  /// Convert response to JSON
  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data,
    'message': message,
    'code': code,
    'statusCode': statusCode,
    'error': error?.toString(),
  };

  @override
  String toString() => 'ApiResponse(success: $success, message: $message)';
}

/// Paginated Response Model
class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNextPage;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final List<T> items = [];
    if (json['items'] is List) {
      items.addAll(
        (json['items'] as List)
            .map((e) => fromJsonT(e as Map<String, dynamic>)),
      );
    }

    return PaginatedResponse(
      items: items,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => {
    'items': items.map(toJsonT).toList(),
    'page': page,
    'pageSize': pageSize,
    'total': total,
    'totalPages': totalPages,
    'hasNextPage': hasNextPage,
  };
}
