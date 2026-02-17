import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/login_request.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

// Auth State
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;
  final String? accessToken;
  final String? refreshToken;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.accessToken,
    this.refreshToken,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  String toString() => 'AuthState('
      'isLoading: $isLoading, '
      'isAuthenticated: $isAuthenticated, '
      'user: $user, '
      'error: $error)';
}

// Auth Provider
class AuthNotifier extends StateNotifier<AuthState> {
  final StorageService _storageService;
  final ApiService _apiService;

  AuthNotifier({
    required StorageService storageService,
    required ApiService apiService,
  })  : _storageService = storageService,
        _apiService = apiService,
        super(const AuthState()) {
    _initializeAuth();
  }

  /// Initialize auth state from storage
  Future<void> _initializeAuth() async {
    try {
      final token = _storageService.getAccessToken();
      final userData = _storageService.getUserData();

      // Attach stored token to ApiService so Dio has Authorization header
      if (token != null && token.isNotEmpty) {
        try {
          _apiService.updateAuthToken(token);
        } catch (_) {}
      }

      // Debug: indicate whether token/user data were present on startup
      try {
        // Avoid printing full token
        print('Auth init - tokenPresent: ${token != null && token.isNotEmpty}, userDataPresent: ${userData != null}');
      } catch (_) {}

      if (token != null && token.isNotEmpty && userData != null) {
        final user = UserModel.fromJson(jsonDecode(userData));
        print('[AUTH] 📦 Restored User from Storage:');
        print('[AUTH]   - Username: ${user.username}');
        print('[AUTH]   - Email: ${user.email}');
        print('[AUTH]   - First Name: ${user.firstName}');
        
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          accessToken: token,
        );
      } else {
        print('[AUTH] ⚠️  No auth data in storage');
      }
    } catch (e) {
      print('[AUTH] ❌ Error initializing auth: $e');
    }
  }

  /// Login with username and password via Node middleware
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call Node middleware login endpoint
      final response = await _apiService.post<Map<String, dynamic>>(
        'auth/login',
        data: {'username': username, 'password': password},
        useNoAuth: true,
      );

      if (response == null || response['status'] != 'success') {
        throw Exception('Login failed: ${response?['message'] ?? 'Unknown error'}');
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid login response');
      }

      final token = data['token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw Exception('Missing token or user data');
      }

      // Create user model from response
      print('[AUTH] 🔐 Login Response User Data: ${userData.toString()}');
      
      final user = UserModel(
        id: userData['id']?.toString() ?? '0',
        email: userData['email'] ?? '',
        username: userData['username'] ?? userData['user_name'],
        firstName: userData.containsKey('first_name') ? userData['first_name'] ?? '' : (userData['firstName'] ?? ''),
        lastName: userData.containsKey('last_name') ? userData['last_name'] ?? '' : (userData['lastName'] ?? ''),
        companyId: userData.containsKey('companyId') ? (userData['companyId']?.toString()) : (userData['company_id']?.toString()),
        companyName: userData.containsKey('companyName') ? userData['companyName'] : (userData['company_name'] ?? null),
        createdAt: DateTime.now(),
      );
      
      print('[AUTH] ✅ User Model Created:');
      print('[AUTH]   - Username: ${user.username}');
      print('[AUTH]   - Email: ${user.email}');
      print('[AUTH]   - First Name: ${user.firstName}');

      // Save to storage
      await _storageService.setAccessToken(token);
      if (refreshToken != null) await _storageService.setRefreshToken(refreshToken);
      await _storageService.setUserData(jsonEncode(user.toJson()));

      // Update API service with token
      _apiService.updateAuthToken(token);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        accessToken: token,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout
  Future<bool> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // TODO: Call logout API if needed
      // await _apiService.post('/auth/logout');

      // Clear storage
      await _storageService.clearTokens();
      await _storageService.clearUserData();

      // Clear API auth
      _apiService.clearAuthToken();

      state = const AuthState();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = _storageService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        await logout();
        return false;
      }

      // TODO: Call refresh token API
      // final response = await _apiService.post<LoginResponse>(
      //   '/auth/refresh',
      //   data: {'refreshToken': refreshToken},
      //   fromJson: (json) => LoginResponse.fromJson(json),
      //   useNoAuth: true,
      // );

      // Mock response
      final newAccessToken = 'mock_access_token_refreshed_${DateTime.now()}';

      await _storageService.setAccessToken(newAccessToken);
      _apiService.updateAuthToken(newAccessToken);

      state = state.copyWith(accessToken: newAccessToken);

      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(UserModel user) async {
    state = state.copyWith(isLoading: true);

    try {
      // TODO: Call update profile API
      // final response = await _apiService.put<UserModel>(
      //   '/users/profile',
      //   data: user.toJson(),
      //   fromJson: (json) => UserModel.fromJson(json),
      // );

      await _storageService.setUserData(jsonEncode(user.toJson()));

      state = state.copyWith(
        isLoading: false,
        user: user,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Get current user
  UserModel? getCurrentUser() => state.user;

  /// Check if user is authenticated
  bool isAuthenticated() => state.isAuthenticated;

  /// Get current token
  String? getAccessToken() => state.accessToken;
}

// Providers
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    baseUrl: 'http://192.168.0.101:3001/api/', // Node middle-layer; change to 10.0.2.2 for Android emulator if needed
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final apiService = ref.watch(apiServiceProvider);

  return AuthNotifier(
    storageService: storage,
    apiService: apiService,
  );
});

// Convenience selectors
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
