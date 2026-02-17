import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

/// User Profile Data Model
class UserProfileData {
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final String? company;
  final String? companyId;
  final String role;
  
  UserProfileData({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.profileImageUrl,
    this.company,
    this.companyId,
    required this.role,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImageUrl: json['profile_image_url'] ?? json['profileImageUrl'],
      company: json['company'] ?? json['companyName'],
      companyId: json['company_id']?.toString() ?? json['companyId'],
      role: json['role'] ?? 'User',
    );
  }

  factory UserProfileData.fromAuthState(UserModel user) {
    return UserProfileData(
      username: user.username,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      profileImageUrl: user.profileImageUrl,
      company: user.companyName,
      companyId: user.companyId?.toString(),
      role: user.role,
    );
  }
}

// Provider for CacheService
final cacheServiceProvider = Provider((ref) {
  return CacheService();
});

// Profile Provider - Fetches from backend
final userProfileProvider = FutureProvider<UserProfileData>((ref) async {
  try {
    final apiService = ref.watch(apiServiceProvider);
    final cacheService = ref.watch(cacheServiceProvider);
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    // Try cache first (profile doesn't change often)
    final cached = await cacheService.get('user_profile');
    if (cached != null) {
      try {
        return UserProfileData.fromJson(Map<String, dynamic>.from(cached as Map));
      } catch (_) {}
    }

    // Fetch from backend
    final response = await apiService.get<Map<String, dynamic>>(
      'accounts/profile/',
      fromJson: (json) => json,
    );

    if (response != null) {
      // Cache for 24 hours
      await cacheService.set('user_profile', response, Duration(hours: 24));
      return UserProfileData.fromJson(response);
    }

    // Fallback to auth user data
    if (authState.user != null) {
      return UserProfileData.fromAuthState(authState.user!);
    }

    throw Exception('Failed to fetch profile data');
  } catch (e) {
    // Return basic data from auth state instead of erroring
    final authState = ref.watch(authProvider);
    if (authState.user != null) {
      return UserProfileData.fromAuthState(authState.user!);
    }
    rethrow;
  }
});
