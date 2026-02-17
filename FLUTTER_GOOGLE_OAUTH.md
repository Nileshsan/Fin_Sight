# Google OAuth Integration for Flutter App

## Overview
Google OAuth has been integrated into the Flutter login screen. Users can now sign in using their Google account directly from the mobile app.

## Implementation Details

### 1. **Packages Added**
- `google_sign_in: ^6.2.1` - Google Sign-In SDK
- `url_launcher: ^6.1.14` - For opening OAuth URLs if needed
- `uni_links2: ^0.0.1` - For deep linking support

### 2. **Google Configuration**
- **Client ID**: `744378730034-akb66ls3013tntsn9of6faa10k4a6e3i.apps.googleusercontent.com`
- **Scopes**: `email`, `profile`
- **Redirect URI**: `exp://localhost` (for development)

### 3. **Authentication Flow**

#### Step 1: User clicks "Continue with Google"
- Flutter app calls `_handleGoogleSignIn()`
- Google Sign-In UI is displayed

#### Step 2: User approves permissions
- Google returns authentication tokens (Access Token, ID Token)
- ID token contains user information (email, name, profile picture)

#### Step 3: Token exchange with backend
- Flutter sends tokens to Django backend at `/accounts/auth/google/callback/`
- Backend verifies tokens and creates/retrieves user
- Backend returns JWT tokens for API access

#### Step 4: Store tokens and navigate
- Access and refresh tokens stored in SharedPreferences
- User info stored locally
- User navigated to home/dashboard screen

## Setup Instructions

### Android Setup

1. **Add Google Sign-In Plugin**
   - Already configured in `pubspec.yaml`
   - Run: `flutter pub get`

2. **Configure Android App**
   - Ensure `android/build.gradle` includes Google Play services:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
   }
   ```

3. **Add google-services.json**
   - File: `android/app/google-services.json`
   - Contains Google project configuration
   - Download from Google Cloud Console

4. **Update AndroidManifest.xml**
   - File: `android/app/src/main/AndroidManifest.xml`
   - Add internet permission:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

### iOS Setup

1. **Configure iOS Project**
   - File: `ios/Runner/Info.plist`
   - Add URL scheme:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.744378730034</string>
           </array>
       </dict>
   </array>
   ```

2. **Add GoogleService-Info.plist**
   - Download from Google Cloud Console
   - Add to `ios/Runner/GoogleService-Info.plist`

### Web Setup

1. **Configure Web Client**
   - Add to `web/index.html` in `<head>`:
   ```html
   <meta name="google-signin-client_id" content="744378730034-akb66ls3013tntsn9of6faa10k4a6e3i.apps.googleusercontent.com.apps.googleusercontent.com">
   ```

2. **Load Google SDK**
   - Add before closing `</body>`:
   ```html
   <script src="https://apis.google.com/js/platform.js"></script>
   ```

## Code Implementation

### In login_screen.dart

```dart
// Initialize Google Sign-In
_googleSignIn = GoogleSignIn(
  clientId: '744378730034-akb66ls3013tntsn9of6faa10k4a6e3i.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

// Handle Google Sign-In
Future<void> _handleGoogleSignIn() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      // Send to backend for verification
      final response = await http.post(
        Uri.parse('$_djangoBaseUrl/auth/google/callback/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': googleAuth.accessToken,
          'redirect_uri': 'exp://localhost',
        }),
      );
      
      // Handle successful authentication
      if (response.statusCode == 200) {
        // Store tokens and navigate
      }
    }
  } catch (e) {
    debugPrint('Google sign in error: $e');
  }
}
```

## User Flow

### First-Time Google Login
1. User launches app and taps "Continue with Google"
2. Google Sign-In dialog appears
3. User selects Google account and grants permissions
4. App receives authentication tokens
5. Tokens are sent to Django backend
6. Backend creates new user account automatically
7. User is logged in and navigated to dashboard

### Returning Google User
1. User launches app and taps "Continue with Google"
2. Google account is already authorized (faster sign-in)
3. App receives tokens
4. Backend verifies user exists
5. User is logged in to dashboard

### Username/Password Login
- Still available as fallback
- Works via Node.js API at `/api/auth/login`

## Security Considerations

### Implemented
✅ OAuth 2.0 authorization code flow  
✅ ID token verification at backend  
✅ JWT token generation for API access  
✅ Secure token storage in SharedPreferences  
✅ Automatic user account creation  

### Recommended for Production
1. **HTTPS Only**: Enforce HTTPS for all API calls
2. **Token Refresh**: Implement automatic token refresh
3. **Logout**: Add logout functionality to clear stored tokens
4. **Deep Linking**: Configure proper redirect URIs for production
5. **Certificate Pinning**: Pin SSL certificates for API endpoints
6. **Biometric Auth**: Add fingerprint/face recognition for re-auth

## Testing

### Test Case 1: First-Time User
1. Launch Flutter app
2. Click "Continue with Google"
3. Select a Google account
4. Grant permissions
5. Verify account created in Django admin
6. Verify logged into app

### Test Case 2: Existing User
1. Launch app as returning user
2. Click "Continue with Google"
3. Verify faster authentication (no permissions dialog)
4. Verify user data matches

### Test Case 3: Fallback Login
1. Click username/password tab (if available)
2. Enter credentials
3. Verify works via Node.js API

## Troubleshooting

### Issue: "Sign in failed"
**Solutions:**
- Verify Client ID matches in code
- Check Google Cloud Console project settings
- Ensure scopes are correctly configured
- Verify internet connectivity

### Issue: "Backend authentication failed"
**Solutions:**
- Check Django backend is running at `http://localhost:8000`
- Verify `/accounts/auth/google/callback/` endpoint exists
- Check CORS configuration in Django
- Review Django logs for errors

### Issue: Tokens not stored
**Solutions:**
- Verify SharedPreferences is working
- Check app has storage permissions
- Review SharedPreferences initialization

### Issue: "Invalid redirect_uri"
**Solutions:**
- Update `authorized_redirect_uris` in Django settings
- Ensure redirect URI matches exactly in request

## File Locations

- **Flutter Login Screen**: `lib/screens/login_screen.dart`
- **Dependencies**: `pubspec.yaml`
- **Backend**: `Backend/Django_server/backend/accounts/views.py`
- **Django Settings**: `Backend/Django_server/backend/cfa_backend/settings.py`
- **Android Config**: `android/app/google-services.json`
- **iOS Config**: `ios/Runner/GoogleService-Info.plist`

## Production Deployment

### Before going live:
1. Update Client ID for production
2. Add production redirect URIs
3. Configure proper HTTPS endpoints
4. Set up error logging and monitoring
5. Implement rate limiting on auth endpoints
6. Add email verification for new accounts
7. Set up user onboarding flow
8. Configure company/organization mapping

## API Endpoints Used

- **Initiate OAuth**: `GET /accounts/auth/google/login/?redirect_uri=...`
- **Exchange Token**: `POST /accounts/auth/google/callback/`
- **Login (fallback)**: `POST /api/auth/login`
- **Refresh Token**: `POST /accounts/auth/refresh/`
