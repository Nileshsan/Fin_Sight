# Flutter Architecture & File Tree

## 📁 Complete Directory Structure

```
Application/
│
├── 📄 pubspec.yaml                          ✅ Dependency management (25+ packages)
├── 📄 main.dart                             ✅ App entry point with Riverpod
├── 📄 SETUP_COMPLETE.md                     ✅ Setup completion guide
├── 📄 FLUTTER_PROJECT_SETUP.md              ✅ Detailed setup documentation
├── 📄 PROGRESS_TRACKER.md                   ✅ Implementation tracking
├── 📄 QUICK_REFERENCE.md                    ✅ Developer quick reference
│
├── 📁 lib/
│   ├── 📄 main.dart                         ✅ Application root widget
│   │
│   ├── 📁 config/
│   │   ├── 📄 router_config.dart            ✅ GoRouter configuration (all routes)
│   │   └── 📄 app_config.dart               ⏳ App-level constants (optional)
│   │
│   ├── 📁 screens/
│   │   ├── 📁 auth/
│   │   │   ├── 📄 splash_screen.dart        ✅ Loading/splash screen
│   │   │   └── 📄 login_screen.dart         ✅ Login form UI
│   │   │
│   │   └── 📁 app/
│   │       ├── 📁 dashboard/
│   │       │   └── 📄 dashboard_screen.dart ⏳ Dashboard overview
│   │       ├── 📁 transactions/
│   │       │   ├── 📄 transactions_screen.dart
│   │       │   ├── 📄 transaction_detail_screen.dart
│   │       │   └── 📄 add_transaction_screen.dart
│   │       ├── 📁 cashflow/
│   │       │   └── 📄 cashflow_screen.dart
│   │       └── 📁 clients/
│   │           ├── 📄 clients_screen.dart
│   │           └── 📄 client_detail_screen.dart
│   │
│   ├── 📁 services/
│   │   ├── 📄 api_service.dart              ✅ Dio HTTP client (320 lines)
│   │   ├── 📄 storage_service.dart          ✅ SharedPreferences wrapper (180 lines)
│   │   ├── 📄 network_service.dart          ⏳ Network connectivity monitoring
│   │   ├── 📄 logger_service.dart           ⏳ Advanced logging
│   │   ├── 📄 cache_service.dart            ⏳ Response caching
│   │   └── 📄 notification_service.dart     ⏳ Push notifications
│   │
│   ├── 📁 providers/
│   │   ├── 📄 auth_provider.dart            ✅ Riverpod auth state (280 lines)
│   │   ├── 📄 theme_provider.dart           ⏳ Theme management
│   │   ├── 📄 dashboard_provider.dart       ⏳ Dashboard data
│   │   ├── 📄 transactions_provider.dart    ⏳ Transaction data
│   │   ├── 📄 cashflow_provider.dart        ⏳ Cashflow data
│   │   └── 📄 clients_provider.dart         ⏳ Clients data
│   │
│   ├── 📁 models/
│   │   ├── 📄 api_response.dart             ✅ Generic API wrapper (90 lines)
│   │   ├── 📄 user_model.dart               ✅ User data model (120 lines)
│   │   ├── 📄 login_request.dart            ✅ Auth request/response (140 lines)
│   │   ├── 📄 transaction_model.dart        ⏳ Transaction data model
│   │   ├── 📄 cashflow_data.dart            ⏳ Cashflow data model
│   │   ├── 📄 company_model.dart            ⏳ Company/account model
│   │   ├── 📄 party_balance_model.dart      ⏳ Customer/party model
│   │   └── 📄 bank_balance_model.dart       ⏳ Bank balance model
│   │
│   ├── 📁 widgets/
│   │   ├── 📄 themed_text.dart              ⏳ Custom text styling
│   │   ├── 📄 themed_view.dart              ⏳ Custom container
│   │   ├── 📄 transaction_card.dart         ⏳ Transaction list item
│   │   ├── 📄 bank_balance_input.dart       ⏳ Bank balance input
│   │   ├── 📄 cashflow_graph.dart           ⏳ Cashflow chart
│   │   ├── 📄 payment_prediction_card.dart  ⏳ Prediction card
│   │   ├── 📄 error_overlay.dart            ⏳ Error display
│   │   ├── 📄 loading_indicator.dart        ⏳ Loading spinner
│   │   ├── 📄 empty_state.dart              ⏳ Empty data state
│   │   ├── 📄 collapsible.dart              ⏳ Collapsible widget
│   │   ├── 📄 animated_gradient.dart        ⏳ Animated gradient bg
│   │   └── 📄 early_payment_discount_card.dart ⏳ Discount card
│   │
│   ├── 📁 constants/
│   │   ├── 📄 app_colors.dart               ✅ Color system (250 lines)
│   │   ├── 📄 app_strings.dart              ✅ String constants (180 lines)
│   │   ├── 📄 app_themes.dart               ⏳ Theme definitions
│   │   └── 📄 app_dimens.dart               ⏳ Dimension constants
│   │
│   ├── 📁 utils/
│   │   ├── 📄 formatters.dart               ⏳ Date/currency formatting
│   │   ├── 📄 validators.dart               ⏳ Input validation
│   │   ├── 📄 error_handler.dart            ⏳ Error parsing
│   │   ├── 📄 extensions.dart               ⏳ String/DateTime extensions
│   │   ├── 📄 constants_helper.dart         ⏳ Constant helpers
│   │   ├── 📄 date_utils.dart               ⏳ Date utilities
│   │   ├── 📄 permission_helper.dart        ⏳ Permission requests
│   │   ├── 📄 device_info.dart              ⏳ Device information
│   │   ├── 📄 deeplink_handler.dart         ⏳ Deep linking
│   │   ├── 📄 api_utils.dart                ⏳ API helpers
│   │   ├── 📄 network_utils.dart            ⏳ Network utilities
│   │   └── 📄 json_utils.dart               ⏳ JSON utilities
│   │
│   ├── 📁 exceptions/
│   │   └── 📄 api_exceptions.dart           ✅ Custom exceptions (210 lines)
│   │
│   ├── 📁 test/                             ⏳ Test files (optional)
│   │
│   └── Other files
│       ├── 📄 test_google_auth.dart         (Existing)
│       └── 📄 app_config.dart               (Existing)
│
├── 📁 android/                              ✅ Android configuration
│   ├── app/
│   │   └── build.gradle                     (Gradle build)
│   ├── gradle/
│   └── settings.gradle
│
├── 📁 ios/                                  ✅ iOS configuration
│   └── Runner/
│       └── Info.plist
│
├── 📁 web/                                  ✅ Web build
│   └── index.html
│
├── 📁 windows/                              ✅ Windows build
├── 📁 linux/                                ✅ Linux build
├── 📁 macos/                                ✅ macOS build
│
└── 📁 assets/                               ✅ App resources
    ├── images/
    └── fonts/
```

## 🏗️ Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    🎨 PRESENTATION LAYER                    │
│  Screens, Widgets, Navigation, Theme                        │
│                                                              │
│  lib/screens/     lib/widgets/    lib/constants/            │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│              🔄 STATE MANAGEMENT LAYER                      │
│  Riverpod Providers, State Notifiers                        │
│                                                              │
│  lib/providers/                                             │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│              📡 BUSINESS LOGIC LAYER                        │
│  Services: API, Storage, Network, Logger, Cache            │
│                                                              │
│  lib/services/                                              │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│              💾 DATA LAYER                                  │
│  Models, API Responses, Exceptions                         │
│                                                              │
│  lib/models/      lib/exceptions/                           │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│          🌐 EXTERNAL LAYER                                  │
│  Backend APIs, Local Storage, Device                        │
│                                                              │
│  HTTP    SharedPreferences    Device APIs                   │
└─────────────────────────────────────────────────────────────┘
```

## 🔀 Data Flow Diagram

```
User Interaction
       │
       ▼
    Widget
       │
       ▼
   GoRouter
       │
       ▼
   Screen
       │
       ▼
   Riverpod Provider (ref.read/watch)
       │
       ▼
   Service (API/Storage)
       │
  ┌────┴────┐
  ▼         ▼
API      Storage
(Dio)   (SharedPref)
  │         │
  └────┬────┘
       ▼
  Backend/Device
```

## 📊 Component Relationships

```
main.dart
    ├── ProviderScope (Riverpod)
    │   └── MaterialApp.router
    │       └── GoRouter (router_config.dart)
    │           ├── /splash → SplashScreen
    │           ├── /login → LoginScreen
    │           │   └── Listens: authProvider
    │           ├── /dashboard → DashboardScreen
    │           │   └── Listens: dashboardProvider
    │           ├── /transactions → TransactionsScreen
    │           │   └── Listens: transactionsProvider
    │           ├── /cashflow → CashflowScreen
    │           └── /clients → ClientsScreen
    │
    └── Theme (AppTheme)
        ├── Colors (AppColors)
        └── Strings (AppStrings)

Providers
    ├── authProvider (StateNotifier<AuthState>)
    │   └── Uses: ApiService, StorageService
    ├── themeProvider
    ├── dashboardProvider
    │   └── Uses: ApiService
    ├── transactionsProvider
    │   └── Uses: ApiService
    ├── cashflowProvider
    │   └── Uses: ApiService
    └── clientsProvider
        └── Uses: ApiService

Services
    ├── ApiService
    │   ├── Uses: Dio
    │   ├── Interceptors: Auth, Logging, Error
    │   └── Methods: GET, POST, PUT, DELETE, PATCH
    │
    ├── StorageService
    │   ├── Uses: SharedPreferences
    │   ├── Token Management
    │   └── User Data Persistence
    │
    ├── NetworkService (pending)
    │   └── Uses: connectivity_plus
    │
    └── LoggerService (pending)
        └── Uses: logger package

Models
    ├── ApiResponse<T> (Generic wrapper)
    ├── UserModel (User data + copyWith)
    ├── LoginRequest/LoginResponse
    ├── TransactionModel (pending)
    ├── CashflowData (pending)
    ├── CompanyModel (pending)
    ├── PartyBalance (pending)
    └── BankBalance (pending)

Exceptions
    └── api_exceptions.dart
        ├── AppException (base)
        ├── ApiException
        ├── NetworkException
        ├── ServerException
        ├── ClientException
        ├── UnauthorizedException
        ├── ForbiddenException
        ├── ParsingException
        └── ValidationException
```

## 🔐 Authentication Flow

```
User enters credentials
        │
        ▼
LoginScreen
        │
        ▼
ref.read(authProvider.notifier).login(email, password)
        │
        ▼
ApiService.post('/auth/login')
        │
        ▼
Backend API
        │
        ▼
LoginResponse (access_token + user)
        │
        ▼
StorageService.setAccessToken()
StorageService.setUserData()
        │
        ▼
Update authProvider state
        │
        ▼
GoRouter redirect → /dashboard
        │
        ▼
Dashboard renders with currentUserProvider
```

## 🎯 State Management Pattern (Riverpod)

```
Provider Definition
    │
    ├── authProvider (StateNotifierProvider<AuthNotifier, AuthState>)
    │   │
    │   ├── AuthState (sealed class)
    │   │   ├── isLoading: bool
    │   │   ├── isAuthenticated: bool
    │   │   ├── user: UserModel?
    │   │   ├── error: String?
    │   │   ├── accessToken: String?
    │   │   └── refreshToken: String?
    │   │
    │   └── AuthNotifier extends StateNotifier
    │       ├── login(email, password) → Future<bool>
    │       ├── logout() → Future<bool>
    │       ├── refreshToken() → Future<bool>
    │       └── updateProfile(user) → Future<bool>
    │
    └── Derived Providers (Selectors)
        ├── isAuthenticatedProvider → bool
        ├── currentUserProvider → UserModel?
        ├── authLoadingProvider → bool
        └── authErrorProvider → String?

Usage in Widgets
    │
    ├── ConsumerWidget
    │   │
    │   └── build(context, ref) {
    │       ├── ref.watch(authProvider) → AuthState
    │       ├── ref.watch(currentUserProvider) → UserModel?
    │       └── ref.read(authProvider.notifier) → AuthNotifier
    │       }
    │
    └── ConsumerStatefulWidget
        │
        └── build(context, ref) {
            └── Same access as ConsumerWidget
            }
```

## 📱 Screen Navigation Map

```
                    ┌─── splash_screen
                    │
            start ──┤
                    │
                    └─── No Token ──┬─── login_screen ──┬─── Sign up (pending)
                                    │                    │
                                    │                    └─── Forgot password (pending)
                                    │
                                    └─── Token ──┬─── dashboard_screen
                                                 │
                                                 ├─── transactions_screen
                                                 │    │
                                                 │    ├─── transaction_detail
                                                 │    │
                                                 │    └─── add_transaction
                                                 │
                                                 ├─── cashflow_screen
                                                 │
                                                 ├─── clients_screen
                                                 │    │
                                                 │    └─── client_detail
                                                 │
                                                 ├─── profile_screen
                                                 │
                                                 └─── settings_screen
                                                      │
                                                      └─── Logout ──► login_screen
```

## 📊 Package Dependencies Map

```
Core
├── flutter
├── flutter_riverpod          → State management
└── go_router                 → Navigation

UI & Design
├── cupertino_icons
├── google_fonts
├── material 3 (built-in)
└── flutter (material/cupertino)

Networking
├── dio                       → HTTP client
├── connectivity_plus         → Network status
└── http                      → Fallback HTTP

Storage & Persistence
├── shared_preferences        → Key-value storage
├── hive                      → Local database
└── hive_flutter

Authentication & Security
├── google_sign_in           → OAuth
├── jwt_decoder              → JWT parsing
└── dart:convert             → JSON encoding

Utilities
├── intl                      → Localization/formatting
├── logger                    → Logging
├── equatable                 → Value comparison
├── uuid                      → ID generation
├── json_annotation           → JSON serialization
└── freezed_annotation        → Immutable models

Development & Code Generation
├── build_runner             → Code generation runner
├── freezed                  → Immutable model generator
├── json_serializable        → JSON converter generator
├── hive_generator           → Hive model generator
└── riverpod_generator       → Riverpod code generator
```

## ✅ Implementation Status

```
FOUNDATION LAYER (Week 0) ✅ COMPLETE
├── Project structure          [████████] 100%
├── Core dependencies          [████████] 100%
├── Services (2/6)             [████░░░░] 33%
├── Models (3/8)               [███░░░░░] 38%
├── Providers (1/6)            [██░░░░░░] 17%
├── Screens (2/15+)            [████░░░░] 13%
└── Constants & Utils          [████░░░░] 50%

AUTHENTICATION LAYER (Week 1) 🟡 PENDING
├── Auth Provider              [████████] 100%
├── Login Screen               [████████] 100%
├── Signup Flow                [░░░░░░░░] 0%
├── Google Sign In             [░░░░░░░░] 0%
├── Token Refresh              [░░░░░░░░] 0%
└── Real API Integration       [░░░░░░░░] 0%

FEATURE SCREENS (Week 2-4) 🟡 PENDING
├── Dashboard                  [░░░░░░░░] 0%
├── Transactions               [░░░░░░░░] 0%
├── Cashflow Analysis          [░░░░░░░░] 0%
├── Clients Management         [░░░░░░░░] 0%
└── Settings/Profile           [░░░░░░░░] 0%

WIDGETS & POLISH (Week 5) 🟡 PENDING
├── Custom Widgets             [░░░░░░░░] 0%
├── Charts & Graphs            [░░░░░░░░] 0%
├── Error Handling UI          [░░░░░░░░] 0%
└── Animations                 [░░░░░░░░] 0%

TESTING & RELEASE (Week 6) 🟡 PENDING
├── Unit Tests                 [░░░░░░░░] 0%
├── Widget Tests               [░░░░░░░░] 0%
├── Integration Tests          [░░░░░░░░] 0%
└── Build & Deployment         [░░░░░░░░] 0%
```

---

**Legend:**
- ✅ Complete & Ready
- 🟡 Pending (Next Phase)
- ⏳ Planned (Future Phase)
- 📄 File
- 📁 Folder
- `[████░░░░]` Progress indicator
