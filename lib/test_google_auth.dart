import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pbs_finsight/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleAuthTester {
  static const String backendUrl = AppConfig.nodeJsBaseUrl; // Use Node.js gateway by default
  static const String googleClientId =
      '744378730034-akb66ls3013tntsn9of6faa10k4a6e3i.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: googleClientId,
    scopes: ['email', 'profile'],
  );

  Future<void> runTests() async {
    print('🔍 Starting Google Authentication Tests...\n');

    // Test 1: Check if Google Sign-In is initialized
    await _testGoogleSignInInitialization();

    // Test 2: Check SharedPreferences
    await _testSharedPreferences();

    // Test 3: Try to sign in silently
    await _testSilentSignIn();

    // Test 4: Check backend connectivity
    await _testBackendConnectivity();

    // Test 5: Validate google-services.json
    await _testGoogleServicesConfig();

    print('\n✅ All tests completed!');
  }

  Future<void> _testGoogleSignInInitialization() async {
    print('📱 Test 1: Google Sign-In Initialization');
    try {
      bool isSignedIn = await _googleSignIn.isSignedIn();
      print('   ✓ Google Sign-In SDK initialized');
      print('   ✓ Current sign-in status: ${isSignedIn ? 'Signed In' : 'Signed Out'}');
    } catch (e) {
      print('   ✗ Error initializing Google Sign-In: $e');
    }
    print('');
  }

  Future<void> _testSharedPreferences() async {
    print('💾 Test 2: SharedPreferences Access');
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to read stored tokens
      String? accessToken = prefs.getString('access_token');
      String? refreshToken = prefs.getString('refresh_token');
      String? userEmail = prefs.getString('user_email');
      
      print('   ✓ SharedPreferences accessible');
      print('   - Access Token stored: ${accessToken != null ? '✓' : '✗'}');
      print('   - Refresh Token stored: ${refreshToken != null ? '✓' : '✗'}');
      print('   - User Email stored: ${userEmail != null ? '✓ ($userEmail)' : '✗'}');
      
      if (accessToken == null) {
        print('   ℹ No tokens stored yet (app not authenticated)');
      }
    } catch (e) {
      print('   ✗ Error accessing SharedPreferences: $e');
    }
    print('');
  }

  Future<void> _testSilentSignIn() async {
    print('🔐 Test 3: Silent Sign-In Attempt');
    try {
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      
      if (account != null) {
        print('   ✓ Silent sign-in successful');
        print('   - Email: ${account.email}');
        print('   - Display Name: ${account.displayName}');
        
        // Get ID token
        final googleKey = await account.authentication;
        print('   - ID Token available: ${googleKey.idToken != null ? '✓' : '✗'}');
        print('   - Access Token available: ${googleKey.accessToken != null ? '✓' : '✗'}');
      } else {
        print('   ℹ No user currently signed in (silent sign-in returned null)');
      }
    } catch (e) {
      print('   ✗ Error during silent sign-in: $e');
      print('   ℹ This may be expected if user is not signed in');
    }
    print('');
  }

  Future<void> _testBackendConnectivity() async {
    print('🌐 Test 4: Backend Connectivity');
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/health/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('   ✓ Backend is reachable');
        print('   ✓ Status Code: ${response.statusCode}');
      } else {
        print('   ⚠ Backend responded but with status: ${response.statusCode}');
      }
    } catch (e) {
      print('   ✗ Cannot reach backend at $backendUrl');
      print('   ℹ Error: $e');
      print('   ℹ Make sure backend is running and URL is correct');
    }
    print('');
  }

  Future<void> _testGoogleServicesConfig() async {
    print('⚙️  Test 5: Google Services Configuration');
    print('   Configuration Details:');
    print('   - Client ID: $googleClientId');
    print('   - Scopes: [email, profile]');
    print('   - Android: google-services.json should be at android/app/');
    print('   - iOS: GoogleService-Info.plist should be at ios/Runner/');
    print('');
  }

  Future<bool> testFullAuthFlow() async {
    print('🔄 Testing Full Authentication Flow...\n');
    
    try {
      // Step 1: Sign out first
      await _googleSignIn.signOut();
      print('✓ Cleared previous session');

      // Step 2: Sign in
      final account = await _googleSignIn.signIn();
      if (account == null) {
        print('✗ User cancelled sign-in');
        return false;
      }
      print('✓ User signed in: ${account.email}');

      // Step 3: Get authentication tokens
      final auth = await account.authentication;
      print('✓ Got authentication tokens');

      // Step 4: Exchange tokens with backend
      if (auth.idToken != null) {
        final response = await _exchangeTokenWithBackend(auth.idToken!);
        if (response) {
          print('✓ Backend token exchange successful');
          return true;
        }
      }
    } catch (e) {
      print('✗ Error in authentication flow: $e');
    }
    return false;
  }

  Future<bool> _exchangeTokenWithBackend(String idToken) async {
    try {
      // Route token exchange through Node.js gateway so it proxies to Django
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/google/callback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store tokens
        final prefs = await SharedPreferences.getInstance();
        if (data['access'] != null) {
          await prefs.setString('access_token', data['access']);
        }
        if (data['refresh'] != null) {
          await prefs.setString('refresh_token', data['refresh']);
        }
        
        print('✓ Tokens stored in SharedPreferences');
        return true;
      } else {
        print('✗ Backend returned status: ${response.statusCode}');
        print('✗ Response: ${response.body}');
      }
    } catch (e) {
      print('✗ Error exchanging tokens: $e');
    }
    return false;
  }
}

void main() {
  final tester = GoogleAuthTester();
  tester.runTests();
}
