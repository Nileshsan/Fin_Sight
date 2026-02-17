# PBS FinSight Flutter App

Modern, cross-platform application for financial cash flow analysis built with Flutter.

## Architecture

```
Flutter App (iOS/Android/Web)
    ↓
    HTTP (Token Auth)
    ↓
Node.js Middle-layer (Port 3001)
    ↓
    HTTP (Bearer Token)
    ↓
Django Backend (Port 8000)
    ↓
PostgreSQL Database
```

## Features

- ✅ **Splash Screen** - Logo animation with initialization sequence
- ✅ **Login/Authentication** - Token-based auth via Node middleware
- ✅ **Dashboard** - 90-day scrollable cashflow chart, bank balance modal, top clients, alerts
- ✅ **Cashflow Screen** - Inflow/outflow summary, forecasts
- ✅ **Parties/Clients** - Client list and details
- ✅ **Discounts** - Early payment discounts with Send Email button
- ✅ **Email Center** - Email draft and send functionality
- ✅ **Profile/Settings** - User profile and app settings
- ✅ **AI Assistant** - AI-powered recommendations

## Setup & Run

### Prerequisites

- Flutter SDK (3.10.7+)
- Dart (comes with Flutter)
- Android Emulator/iOS Simulator or physical device
- Node.js middleware running on port 3001
- Django backend running on port 8000

### Step 1: Install Dependencies

```bash
cd Application
flutter pub get
```

### Step 2: Configure Backend URLs

Edit `lib/config/app_config.dart` to set your backend URLs:

```dart
static const String nodeJsBaseUrl = 'http://localhost:3001';  // Node middleware
static const String djangoBaseUrl = 'http://localhost:8000';  // Django backend (for reference)
```

For **Android Emulator**, use:
```dart
static const String nodeJsBaseUrl = 'http://10.0.2.2:3001';
```

For physical **Android Device**, use your computer's local IP:
```dart
static const String nodeJsBaseUrl = 'http://192.168.1.X:3001';
```

### Step 3: Run the App

**iOS Simulator:**
```bash
flutter run -d "iPhone 15"
```

**Android Emulator:**
```bash
flutter run -d emulator-5554
```

**Physical Device (Android):**
```bash
flutter run
```

**Web (Chrome):**
```bash
flutter run -d chrome
```

## API Flow

### 1. Login Flow

```
Mobile: POST /api/auth/login
  ├─ username, password
  
Node Middleware
  ├─ Validate request
  ├─ Create JWT token
  
Django Backend
  ├─ Verify credentials
  ├─ Generate access token
  ├─ Return user data + token
  
Response: { token, user, status: 'success' }
  └─> Store token in SharedPreferences
  └─> Add to axios default headers as Bearer token
```

### 2. Dashboard Data Flow

```
Mobile: GET /api/payment-analysis-summary/<company_id>
  
Node Middleware (adds auth header)
  ├─ Bearer token validation
  └─> Forward to Django
  
Django Backend
  ├─ Authenticate request
  ├─ Fetch company data
  ├─ Compute cash flow analytics
  └─> Return 90-day forecast, client summary
  
Response: { status: 'success', data: {...} }
  └─> Render in LineChart with horizontal scroll
```

### 3. Email Send Flow

```
Mobile: POST /api/enqueue-email/
  ├─ recipient_email, subject, body
  
Node Middleware
  └─> Forward to Django with Bearer token
  
Django Backend
  ├─ Validate email fields
  ├─ Create EmailQueue entry
  ├─ Queue for background worker
  └─> Return { status: 'success', email_id }
  
Celery Worker (async)
  └─> Send email via SMTP/provider
```

## Key Screens

### Splash Screen
- 4-second initialization
- Brand logo animation
- Checks auth state → routes to Login or Dashboard

### Login Screen
- Username/password input
- Form validation
- Error handling with snackbars
- Routes to Dashboard on success

### Dashboard Screen
- **Bank Balance Modal** (on first visit) - blur backdrop, allows entering starting balance
- **90-Day Cashflow Chart** - LineChart with horizontal scroll and scrollbar
- **Top 5 Clients** - List of upcoming payments
- **Alerts** - No cash in next 10 days, Category D clients
- **Quick Actions** - Add transaction, view cashflow, clients

### Discounts Screen
- List of computed early payment discounts
- Send Email button → opens modal
- Email modal auto-fetches contact, pre-fills subject/body
- POST to `enqueue-email/` endpoint

## Configuration Files

### `lib/config/app_config.dart`
Environment and feature flags for dev/staging/production

### `lib/services/api_service.dart`
HTTP client wrapper using Dio with:
- Token auto-injection
- Error handling
- Request/response interceptors
- Timeout settings (30 seconds)

### `lib/providers/auth_provider.dart`
Riverpod state management for:
- Login / Logout / Refresh token
- User data persistence
- Auth state selectors

### `lib/services/storage_service.dart`
SharedPreferences wrapper for:
- Access token
- Refresh token
- User data (JSON)
- Company info

## Troubleshooting

### "Connection refused" error
- **Check**: Node middleware is running on port 3001
- **Check**: Django is running on port 8000
- **Check**: Firewall allows local connections

### "401 Unauthorized"
- **Check**: Token is correctly stored after login
- **Check**: ApiService is using Bearer prefix: `Authorization: Bearer <token>`
- **Check**: Node middleware is forwarding auth header to Django

### "Permission denied" for email
- **Check**: Django DEFAULT_FROM_EMAIL is configured in settings
- **Check**: Email backend (SMTP/Mailgun/etc.) is configured

### Chart not rendering
- **Check**: `fl_chart` package is installed: `flutter pub get`
- **Check**: 90-day data is returned from API
- **Check**: Async data loading doesn't conflict with widget build

## Build for Production

### Android APK
```bash
flutter build apk --split-per-abi
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle
```

### iOS Archive (App Store)
```bash
flutter build ios
```

### Web Build
```bash
flutter build web
```

## Testing Credentials

For development/demo:
- **Username**: `testuser`
- **Password**: `testpass123`

(Configure actual test users in Django settings)

## Dependencies

Key packages used:
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `dio` - HTTP client
- `fl_chart` - Charts and graphs
- `shared_preferences` - Local storage
- `connectivity_plus` - Network monitoring
- `logger` - Logging
- `google_fonts` - Custom fonts
- `connectivity_plus` - Connectivity checks

## Known Limitations

1. **Splash Screen**: 4-second delay (configure in `splash_screen.dart`)
2. **Chart Scrolling**: Horizontal scroll only (no pinch-zoom yet)
3. **Email Sending**: Requires Celery worker running or email backend configured
4. **OAuth**: Google Sign-In commented out (requires setup in Node middleware)

## Next Steps

1. ✅ Wire login to real API
2. ✅ Add 90-day cashflow chart with scroll
3. ✅ Implement email enqueue
4. ⏳ Add offline mode (sync on reconnect)
5. ⏳ Implement biometric auth
6. ⏳ Add push notifications
7. ⏳ Performance optimization (pagination, lazy loading)

## References

- Flutter Docs: https://flutter.dev/docs
- Riverpod: https://riverpod.dev
- Dio: https://pub.dev/packages/dio
- go_router: https://pub.dev/packages/go_router
- fl_chart: https://pub.dev/packages/fl_chart

---

**Last Updated**: February 12, 2026  
**Flutter Version**: 3.10.7+  
**Dart Version**: 3.x
