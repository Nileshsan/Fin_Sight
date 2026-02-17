/// API Library Utilities
/// Shared API functions and helpers

import 'package:dio/dio.dart';

/// Build API endpoints
class ApiEndpoints {
  static const String baseUrl = 'https://api.example.com';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String register = '/auth/register';
  static const String resetPassword = '/auth/reset-password';
  
  // User endpoints
  static const String getUser = '/user/profile';
  static const String updateUser = '/user/profile';
  static const String getUserSettings = '/user/settings';
  
  // Dashboard endpoints
  static const String getDashboard = '/dashboard';
  static const String getDashboardStats = '/dashboard/stats';
  
  // Transaction endpoints
  static const String getTransactions = '/transactions';
  static const String createTransaction = '/transactions';
  static const String updateTransaction = '/transactions/:id';
  static const String deleteTransaction = '/transactions/:id';
  
  // Cashflow endpoints
  static const String getCashflow = '/cashflow';
  static const String getCashflowForecast = '/cashflow/forecast';
  
  // Settlement endpoints
  static const String getSettlements = '/settlements';
  static const String createSettlement = '/settlements';
}

/// API request builder
class ApiRequest {
  final String method;
  final String endpoint;
  final Map<String, dynamic>? queryParams;
  final Map<String, dynamic>? body;
  final Map<String, dynamic>? headers;
  final bool requiresAuth;

  const ApiRequest({
    required this.method,
    required this.endpoint,
    this.queryParams,
    this.body,
    this.headers,
    this.requiresAuth = true,
  });

  /// Build full URL
  String buildUrl(String baseUrl) {
    final url = '$baseUrl$endpoint';
    if (queryParams == null || queryParams!.isEmpty) {
      return url;
    }

    final queryString = queryParams!.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$url?$queryString';
  }
}

/// API response wrapper
class ApiResponse<T> {
  final T data;
  final int statusCode;
  final Map<String, dynamic>? headers;
  final String? message;

  ApiResponse({
    required this.data,
    required this.statusCode,
    this.headers,
    this.message,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Pagination info
class PaginationInfo {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
