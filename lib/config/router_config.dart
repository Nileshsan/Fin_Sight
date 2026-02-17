import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/app/shell_screen.dart';
import '../screens/app/dashboard_screen.dart';
import '../screens/app/cashflow_screen.dart';
import '../screens/app/parties_screen.dart';
import '../screens/app/discounts_screen.dart';
import '../screens/app/email_center_screen.dart';
import '../screens/app/ai_assistant_screen.dart';
import '../screens/app/profile_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final storageService = StorageService();
      final isAuthenticated = storageService.isAuthenticated();

      // If on splash, always allow
      if (state.matchedLocation == '/splash') {
        return null;
      }

      // If not authenticated and not on auth routes, redirect to login
      if (!isAuthenticated) {
        if (state.matchedLocation == '/login') {
          return null;
        }
        return '/login';
      }

      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && state.matchedLocation == '/login') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main App Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/cashflow',
            name: 'cashflow',
            builder: (context, state) => const CashflowScreen(),
          ),
          GoRoute(
            path: '/parties',
            name: 'parties',
            builder: (context, state) => const PartiesScreen(),
            routes: [],
          ),
          GoRoute(
            path: '/discounts',
            name: 'discounts',
            builder: (context, state) => const DiscountsScreen(),
            routes: [],
          ),
          GoRoute(
            path: '/email',
            name: 'email-center',
            builder: (context, state) => const EmailCenterScreen(),
            routes: [],
          ),
          GoRoute(
            path: '/ai',
            name: 'ai-assistant',
            builder: (context, state) => const AIAssistantScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile-settings',
            builder: (context, state) => const ProfileSettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Page not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    },
  );
});
