# Flutter Project - Quick Reference Guide

## 🚀 Quick Start

```bash
# Navigate to project
cd "c:\Users\Admin\Nilesh_Projects\CFA-3009\CFA\cfa_ai_app\mobile\Application"

# Install dependencies (already done)
flutter pub get

# Run the app
flutter run

# Run on specific device
flutter run -d chrome    # Web
flutter run -d "iPhone"  # iOS
flutter run -d emulator  # Android emulator
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point with ProviderScope & GoRouter
├── config/
│   └── router_config.dart      # All route definitions
├── screens/                    # UI Screens
│   ├── auth/                   # Authentication screens
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   └── ...
│   └── app/                    # Main app screens
│       ├── dashboard/
│       ├── transactions/
│       ├── cashflow/
│       └── clients/
├── services/                   # Business logic layer
│   ├── api_service.dart       # HTTP requests (Dio)
│   ├── storage_service.dart   # Local storage (SharedPreferences)
│   └── ...
├── providers/                  # State management (Riverpod)
│   ├── auth_provider.dart     # Authentication state
│   └── ...
├── models/                     # Data models
│   ├── api_response.dart      # Generic API wrapper
│   ├── user_model.dart
│   └── ...
├── widgets/                    # Reusable UI components
├── constants/                  # App constants
│   ├── app_colors.dart        # Color system
│   └── app_strings.dart       # String constants
├── utils/                      # Utility functions
├── exceptions/                 # Custom exceptions
│   └── api_exceptions.dart
└── config/                     # Configuration

pubspec.yaml                    # Dependencies
```

---

## 🔌 Key Services

### API Service (Dio)
```dart
import 'package:application/services/api_service.dart';

// Get instance
final apiService = ApiService(baseUrl: 'https://api.example.com');

// GET request
final data = await apiService.get<MyModel>(
  '/endpoint',
  fromJson: (json) => MyModel.fromJson(json),
);

// POST request
final result = await apiService.post<MyModel>(
  '/endpoint',
  data: {'key': 'value'},
  fromJson: (json) => MyModel.fromJson(json),
);

// PUT request
final updated = await apiService.put<MyModel>(
  '/endpoint/123',
  data: {'key': 'newValue'},
);

// DELETE request
await apiService.delete('/endpoint/123');

// PATCH request
final patched = await apiService.patch<MyModel>(
  '/endpoint/123',
  data: {'key': 'value'},
);
```

### Storage Service (SharedPreferences)
```dart
import 'package:application/services/storage_service.dart';

final storage = StorageService();

// Initialize (already done in main.dart)
await storage.init();

// Token management
await storage.setAccessToken('token');
String? token = storage.getAccessToken();

// User data
await storage.setUserData(jsonEncode(user.toJson()));
String? userData = storage.getUserData();

// Generic key-value
await storage.setString('key', 'value');
String? value = storage.getString('key');

// Check auth
bool isAuth = storage.isAuthenticated();

// Clear all
await storage.clear();
```

---

## 🎯 State Management (Riverpod)

### Reading State in Widget
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider
    final authState = ref.watch(authProvider);
    
    // Get current user
    final user = ref.watch(currentUserProvider);
    
    return Text(user?.fullName ?? 'Guest');
  }
}
```

### Modifying State
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final success = await ref
            .read(authProvider.notifier)
            .login('email@example.com', 'password');
        
        if (success) {
          context.go('/dashboard');
        }
      },
      child: const Text('Login'),
    );
  }
}
```

### Available Providers
```dart
// Auth
authProvider                 // Full auth state
isAuthenticatedProvider     // Boolean check
currentUserProvider         // Current user
authLoadingProvider         // Loading state
authErrorProvider           // Error message

// Add more as needed
```

---

## 🎨 Colors & Theming

### Using Colors
```dart
import 'package:application/constants/app_colors.dart';

Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.white),
  ),
)

// Available colors
AppColors.primary              // Main brand color
AppColors.secondary            // Secondary color
AppColors.success              // Green
AppColors.warning              // Amber
AppColors.error                // Red
AppColors.info                 // Blue
AppColors.gray100-900          // Grayscale
AppColors.darkBg               // Dark theme background
```

### Theme Switching
```dart
// Light theme is default
// Switch to dark theme system-wide (implement in settings)
ThemeMode.dark    // Dark
ThemeMode.light   // Light
ThemeMode.system  // Follow device
```

---

## 📝 String Constants

```dart
import 'package:application/constants/app_strings.dart';

// Common strings
AppStrings.appName              // 'CFA App'
AppStrings.loading              // 'Loading...'
AppStrings.error                // 'Error'

// Auth strings
AppStrings.login                // 'Login'
AppStrings.email                // 'Email'
AppStrings.password             // 'Password'
AppStrings.forgotPassword       // 'Forgot Password?'

// Screen strings
AppStrings.dashboard            // 'Dashboard'
AppStrings.transactions         // 'Transactions'
AppStrings.cashflow            // 'Cashflow'

// Error messages
AppStrings.noInternet           // 'No internet connection'
AppStrings.invalidEmail         // 'Invalid email address'
AppStrings.unauthorized         // 'Unauthorized'
```

---

## 🗺️ Navigation (GoRouter)

### Navigate To Screen
```dart
// Using context
context.go('/dashboard');
context.go('/transactions');

// Named routes
context.goNamed('dashboard');
context.goNamed('login');

// With parameters
context.go('/transaction/123');
context.goNamed('transaction', pathParameters: {'id': '123'});

// Replace current screen
context.replace('/dashboard');

// Back
context.pop();
```

### Add New Route
Edit `lib/config/router_config.dart`:
```dart
GoRoute(
  path: '/newscreen',
  name: 'newscreen',
  builder: (context, state) => const NewScreen(),
  // Optional: add sub-routes, redirect logic
),
```

---

## ⚠️ Error Handling

### Common Exceptions
```dart
import 'package:application/exceptions/api_exceptions.dart';

try {
  final data = await apiService.get('/endpoint');
} on NetworkException catch (e) {
  print('No internet: ${e.message}');
} on UnauthorizedException catch (e) {
  print('Login required');
  context.go('/login');
} on ServerException catch (e) {
  print('Server error (${e.statusCode}): ${e.message}');
} on ApiException catch (e) {
  print('API error: ${e.message}');
} on AppException catch (e) {
  print('App error: ${e.message}');
}
```

### Throw Custom Exception
```dart
throw ValidationException(
  message: 'Invalid input',
  errors: {'email': 'Invalid email format'},
);

throw UnauthorizedException();

throw ServerException(
  message: 'Server error',
  statusCode: 500,
);
```

---

## 🔐 Authentication Flow

### Login
```dart
final authNotifier = ref.read(authProvider.notifier);
final success = await authNotifier.login('email@test.com', 'password123');

if (success) {
  context.go('/dashboard');
} else {
  // Show error
  final error = ref.read(authErrorProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error ?? 'Login failed')),
  );
}
```

### Logout
```dart
final authNotifier = ref.read(authProvider.notifier);
await authNotifier.logout();
context.go('/login');
```

### Check Auth Status
```dart
final isAuth = ref.watch(isAuthenticatedProvider);
if (isAuth) {
  // User is logged in
} else {
  // User not logged in
}
```

---

## 📦 Adding New Packages

```bash
# Add a new package
flutter pub add package_name

# Add dev dependency
flutter pub add --dev dev_package

# Update all packages
flutter pub upgrade

# Remove package
flutter pub remove package_name
```

---

## 🔨 Code Generation

Some packages require code generation:

```bash
# Generate code once
flutter pub run build_runner build

# Watch for changes (regenerate automatically)
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

**When needed:**
- After adding `@freezed` decorators to models
- After adding `@JsonSerializable()` decorators
- After adding Hive model annotations

---

## 🧪 Building & Deployment

```bash
# Build APK (Android)
flutter build apk

# Build bundle (Android - for Play Store)
flutter build appbundle

# Build IPA (iOS - for App Store)
flutter build ios

# Build for web
flutter build web

# Release build with optimizations
flutter build apk --release
flutter build appbundle --release
```

---

## 📊 Debugging

```bash
# Enable debug logs
flutter run -v

# Verbose logging
export FLUTTER_VERBOSE=true

# Performance testing
flutter run --profile

# Clean build
flutter clean
flutter pub get
flutter run

# Check for issues
flutter analyze

# Run in debug mode
flutter run -d chrome

# Check device list
flutter devices
```

---

## 💡 Pro Tips

1. **Hot Reload**: Press `r` in terminal while `flutter run` is active
2. **Hot Restart**: Press `R` for full restart
3. **Device Inspector**: Run `flutter inspector` to debug widget tree
4. **Network Logging**: Enable in `ApiService` with `Logger()`
5. **Storage Debug**: Print all keys with `storage.getAllKeys()`

---

## 📚 Documentation Links

- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Guide](https://riverpod.dev)
- [GoRouter Guide](https://pub.dev/packages/go_router)
- [Dio Docs](https://pub.dev/packages/dio)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)

---

## 🆘 Troubleshooting

### Package not found
```bash
flutter pub get
flutter pub upgrade
```

### Build fails
```bash
flutter clean
flutter pub get
flutter run
```

### Dart analysis errors
- Check `analysis_options.yaml`
- Run `flutter analyze`
- Fix import issues

### API not responding
- Check API base URL
- Verify network connection
- Check request headers
- Enable verbose logging

### State not updating
- Ensure using `ref.watch()` not `ref.read()`
- Check provider initialization
- Verify state mutations

---

## 📞 Getting Help

1. Check **FLUTTER_PROJECT_SETUP.md** for setup details
2. Review **PROGRESS_TRACKER.md** for implementation status
3. Reference **COMPLETE_FILE_CHECKLIST.md** in parent directory
4. Check error messages in console output
5. Enable verbose logging with `-v` flag

---

**Last Updated**: 2024
**Version**: 1.0
**For**: Flutter Development Team
