import 'package:logger/logger.dart';
import 'storage_service.dart';

/// Authentication Service
/// Handles authentication logic and session management
class AuthService {
  final Logger logger;
  final StorageService storageService;

  AuthService({
    Logger? logger,
    StorageService? storageService,
  })  : logger = logger ?? Logger(),
        storageService = storageService ?? StorageService();

  /// Check if user is currently authenticated
  bool isAuthenticated() {
    final token = storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current access token
  String? getAccessToken() {
    return storageService.getAccessToken();
  }

  /// Get current refresh token
  String? getRefreshToken() {
    return storageService.getRefreshToken();
  }

  /// Clear all authentication data
  Future<bool> clearAuth() async {
    logger.d('Clearing authentication data');
    return await storageService.clearTokens();
  }

  /// Save authentication tokens
  Future<bool> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    logger.d('Saving tokens');
    await storageService.setAccessToken(accessToken);
    if (refreshToken != null) {
      await storageService.setRefreshToken(refreshToken);
    }
    return true;
  }

  /// Check if token needs refresh
  bool shouldRefreshToken() {
    final token = storageService.getAccessToken();
    if (token == null) return false;

    // In a real app, you'd decode the JWT and check expiration
    // For now, just check if token exists
    return token.isNotEmpty;
  }

  /// Validate credentials format
  bool validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  bool validatePassword(String password) {
    // Minimum 6 characters
    return password.length >= 6;
  }

  /// Validate login credentials
  Map<String, String> validateLoginCredentials(String email, String password) {
    final errors = <String, String>{};

    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!validateEmail(email)) {
      errors['email'] = 'Invalid email format';
    }

    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (!validatePassword(password)) {
      errors['password'] = 'Password must be at least 6 characters';
    }

    return errors;
  }

  /// Log authentication event
  void logAuthEvent(String event, {Map<String, dynamic>? data}) {
    logger.i('Auth Event: $event', error: data);
  }
}
