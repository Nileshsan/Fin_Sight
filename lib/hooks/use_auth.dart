import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Custom hook equivalent: useAuth
/// Provides access to authentication state and methods
class UseAuth {
  final WidgetRef ref;

  UseAuth(this.ref);

  /// Get current authentication state
  AuthState get state => ref.watch(authProvider);

  /// Get auth notifier for methods
  AuthNotifier get notifier => ref.read(authProvider.notifier);

  /// Get current user
  UserModel? get user => state.user;

  /// Check if authenticated
  bool get isAuthenticated => state.isAuthenticated;

  /// Get current error
  String? get error => state.error;

  /// Get loading state
  bool get isLoading => state.isLoading;

  /// Get access token
  String? get accessToken => state.accessToken;

  /// Login method
  Future<bool> login(String email, String password) {
    return notifier.login(email, password);
  }

  /// Logout method
  Future<bool> logout() {
    return notifier.logout();
  }

  /// Refresh token method
  Future<bool> refreshToken() {
    return notifier.refreshToken();
  }

  /// Update profile method
  Future<bool> updateProfile(UserModel user) {
    return notifier.updateProfile(user);
  }
}

/// Helper function to use auth in widgets
UseAuth useAuth(WidgetRef ref) {
  return UseAuth(ref);
}

// Import needed for types
import '../models/user_model.dart';
