# 🔍 Backend Communication Analysis: React Native vs Flutter

## Executive Summary

| Aspect | React Native | Flutter |
|--------|-------------|---------|
| **Backend Connection** | ✅ FULLY CONNECTED (Live APIs) | ⚠️ STATIC (Mock Data) |
| **JWT Authentication** | ✅ Yes (Bearer Token) | ✅ Setup (Not Used Yet) |
| **Caching Strategy** | ✅ AsyncStorage + JWT | ✅ SharedPreferences (not used) |
| **API Service** | ✅ Fully Implemented | ✅ Implemented (No Wiring) |
| **Screens Connection** | ✅ Real Data Calls | ❌ Mock Data Only |
| **Status** | Production-Ready | Development Mode |

---

## 📱 React Native App: Fully Connected to Backend

### Flow: Splash → Login → Dashboard

#### 1. **Splash Screen** (`app/(auth)/splash.tsx`)
```
- NO API CALLS in splash
- Just checks AsyncStorage for existing tokens
- Auto-navigates based on token validity
```

#### 2. **Login Screen** (`app/(auth)/login.tsx`)
```typescript
// LIVE API CALL
const response = await api.login(username, password);
// Response includes JWT token + user data
// Stores token in AsyncStorage: sessionToken
// Sets company context
// Checks model training status via API
```

#### 3. **Authentication Flow**
```
USER INPUT
    ↓
POST /api/login/  (API Service)
    ↓
Receives: { token, user, company_id, company_name }
    ↓
Store in AsyncStorage:
  - sessionToken: JWT token
  - userInfo: User data
  - companyContext: { companyId, companyName }
    ↓
API Client auto-adds header: Authorization: Bearer {token}
    ↓
Navigate to Dashboard
```

### API Communication Setup

**Files Involved:**
- `services/api.ts` - Main API client (457 lines)
- `services/NetworkService.ts` - Axios wrapper with interceptors
- `.env` - API_URL = "http://127.0.0.1:8000"
- `config.ts` - API_BASE_URL configuration

**Key Features:**
```typescript
// JWT Token Management
class ApiClient {
  private authToken: string | null = null;
  
  private getAuthHeaders(): Record<string, string> {
    return { Authorization: `Bearer ${this.authToken}` };
  }
}

// Token stored in AsyncStorage
const token = await AsyncStorage.getItem('sessionToken');
api.setAuthToken(token); // Sets for all subsequent requests
```

### Backend Endpoints (Working)

The React Native app calls these LIVE endpoints:

```
POST   /api/login/                        → Login (no auth needed)
GET    /api/user/api-token/               → Get API token
GET    /api/payment-predictions/          → Payment forecasts
GET    /api/payment-analysis-summary/     → Financial summary
GET    /api/party-balances/               → Party receivables
GET    /api/bank-balance/                 → Bank balance
GET    /api/model/status/                 → ML model status
POST   /api/transactions/cashflow/...     → Update cashflow data
```

### Dashboard Data Flow (React Native)

```
Dashboard Screen
    ↓
useEffect(() => {
  fetchPaymentPredictions(companyId)
  fetchPartyBalances(companyId)
  getBankBalance(companyId)
})
    ↓
API calls with JWT token
    ↓
Displays REAL financial data
    ↓
User can filter by period, see actual predictions
```

---

## 🎯 Flutter App: Static (Not Connected)

### Current Status: **DEVELOPMENT MODE - MOCK DATA ONLY**

#### Why Flutter is Static:

1. **Screens Use Mock Data**
   - Dashboard: Hard-coded stats (₹45.8L, +12.3%)
   - Transactions: Fake transaction list
   - Parties: Mock party data
   - No API calls in any screen

2. **Auth Flow is Placeholder**
   ```dart
   // LoginScreen - Line 72
   // TODO: Call login provider here
   // await ref.read(authProvider.notifier).login(email, password);
   
   // For now, just navigate to dashboard
   if (mounted) {
     context.go('/dashboard');
   }
   ```

3. **API Service Exists But Unused**
   - `lib/services/api_service.dart` (364 lines)
   - Has full HTTP client setup (Dio)
   - Has JWT Bearer token support
   - **NOT CALLED BY ANY SCREEN**

4. **Auth Provider Exists But Not Wired**
   - `lib/providers/auth_provider.dart` (274 lines)
   - Has login() method defined
   - **NOT CALLED BY LOGIN SCREEN**
   - Screens bypass it and use mock data

### Flutter Architecture Comparison

```
React Native                    Flutter
─────────────────────────────────────────
Login Screen                    Login Screen
    ↓ calls                         ↓ no call
api.login()                     authProvider.login()
    ↓                               ↓ (NOT WIRED)
API Service                     API Service
    ↓ HTTP                          ↓ (dormant)
Backend: /api/login/            (no backend)
    ↓                               ↓
JWT Token stored                Mock data
    ↓                               ↓
Dashboard gets real data        Dashboard shows ₹45.8L hardcoded
```

---

## 🔌 How React Native Connects to Backend

### 1. **API Configuration**
```typescript
// NetworkService.ts - Line 28
const baseURL = config.API_BASE_URL.endsWith('/') 
  ? `${config.API_BASE_URL}api/` 
  : `${config.API_BASE_URL}/api/`;

// Result: http://127.0.0.1:8000/api/
```

### 2. **Request Interceptor**
```typescript
// Automatically adds JWT to every request
instance.interceptors.request.use(async (config) => {
  const token = await AsyncStorage.getItem('sessionToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

### 3. **Login Example**
```typescript
// api.ts - Line 194
public async login(username: string, password: string) {
  const payload = { username, password };
  const res = await this.ns.post('login/', payload);
  
  // Gets token from response
  const token = res.data?.token || res.data?.access_token;
  
  // Store for future requests
  await AsyncStorage.setItem('sessionToken', token);
  this.ns.setAuthToken(token);
  
  return res;
}
```

### 4. **Subsequent Requests**
```typescript
// All requests now include:
// Authorization: Bearer {token}

public async getPartyBalances(companyId: number) {
  return this.ns.get('party-balances/', 
    { company_id: companyId }, 
    this.getAuthHeaders()  // ← Adds Bearer token
  );
}
```

---

## 🚧 Flutter: What's Missing to Connect

### To Make Flutter Work Like React Native:

**Step 1: Wire Login Screen to Provider**
```dart
// login_screen.dart - Replace Line 72
// From:
// TODO: Call login provider here
// To:
Future<void> _handleLogin() async {
  try {
    await ref.read(authProvider.notifier).login(
      _emailController.text,
      _passwordController.text,
    );
    
    if (mounted) {
      context.go('/dashboard');
    }
  } catch (e) {
    setState(() => _errorMessage = e.toString());
  }
}
```

**Step 2: Implement Login in AuthProvider**
```dart
// auth_provider.dart - auth_provider.dart (already partially exists)
Future<void> login(String email, String password) async {
  state = state.copyWith(isLoading: true);
  
  try {
    final response = await _apiService.login(email, password);
    
    // Store JWT token
    _storageService.setAccessToken(response['token']);
    
    // Update auth state
    state = state.copyWith(
      isAuthenticated: true,
      accessToken: response['token'],
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(error: e.toString(), isLoading: false);
    rethrow;
  }
}
```

**Step 3: Update Screens to Use Providers**
```dart
// dashboard_screen.dart - Replace mock data
@override
Widget build(BuildContext context, WidgetRef ref) {
  // From static mock data
  // To:
  final dashboardData = ref.watch(dashboardProvider);
  
  return dashboardData.when(
    data: (data) => DashboardContent(data: data),
    loading: () => LoadingWidget(),
    error: (err, _) => ErrorWidget(error: err),
  );
}
```

**Step 4: Create Riverpod Providers**
```dart
// Create new file: lib/providers/dashboard_provider.dart
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getDashboard(companyId);
});

// Similar for: cashflow, parties, discounts, email, ai
```

---

## 📊 Detailed Comparison Table

### JWT Token Handling

| Aspect | React Native | Flutter |
|--------|-------------|---------|
| **Storage** | AsyncStorage('sessionToken') | SharedPreferences (configured) |
| **Retrieval** | ✅ In interceptor | ✅ Available in ApiService |
| **Addition to Request** | ✅ Bearer prefix auto | ✅ Code exists, not used |
| **Refresh Logic** | ✅ Implemented | ✅ Framework ready |

### Backend Integration

| Aspect | React Native | Flutter |
|--------|-------------|---------|
| **HTTP Client** | Axios | Dio (better) |
| **API Wrapper** | NetworkService | ApiService |
| **Interceptors** | ✅ Request/Response | ✅ Request/Response |
| **Error Handling** | ✅ Custom exceptions | ✅ Custom exceptions |
| **Timeout** | 120 seconds | 30 seconds |

### Application Layer

| Aspect | React Native | Flutter |
|--------|-------------|---------|
| **Login Flow** | ✅ Calls API | ❌ Mock (TODO) |
| **Dashboard** | ✅ Real data | ❌ Hardcoded stats |
| **Transactions** | ✅ API endpoint | ❌ Mock array |
| **Parties** | ✅ API endpoint | ❌ Mock objects |
| **State Management** | Custom hooks | ✅ Riverpod ready |

---

## 🔑 Key Findings

### ✅ React Native App Status: **PRODUCTION-READY**

1. Full JWT authentication working
2. All screens fetch real data from backend
3. Proper error handling with custom exceptions
4. Token refresh mechanism in place
5. Offline detection (NetworkError handling)
6. AsyncStorage for persistence

### ⚠️ Flutter App Status: **FRAMEWORK READY, NOT CONNECTED**

1. **Has all infrastructure:**
   - ✅ ApiService (Dio client with interceptors)
   - ✅ AuthProvider (Riverpod state management)
   - ✅ JWT Bearer token setup
   - ✅ StorageService for persistence
   - ✅ Custom exception classes

2. **Missing connection layer:**
   - ❌ Login screen not calling API
   - ❌ Screens using mock data instead of providers
   - ❌ No API calls in any business logic
   - ❌ Providers not connected to screens

---

## 🎯 What Needs to Happen

### To Bring Flutter to Production Parity:

**High Priority (1-2 days):**
1. Wire login screen to authProvider ✅ API call on login
2. Create dashboard provider
3. Create parties provider
4. Create cashflow provider
5. Update screens to use providers

**Medium Priority (2-3 days):**
6. Create email provider
7. Create discounts provider
8. Create AI provider
9. Add error handling/retry logic
10. Add loading states

**Polish (1 day):**
11. Add offline detection
12. Add token refresh
13. Add network retry mechanism
14. Testing

---

## 📝 Summary

**React Native:** 
- ✅ **LIVE & WORKING** - All screens communicate with Django backend via JWT
- ✅ User data, predictions, parties, bank balance all fetched from API
- ✅ Production-ready authentication flow

**Flutter:**
- ⚠️ **STATIC/MOCK MODE** - Infrastructure ready but not wired
- ⚠️ UI looks great but shows dummy data
- ⚠️ All API infrastructure exists but unused by screens
- 🟡 **Needs 2-3 days to reach production parity**

The good news: **All the hard parts are done.** Flutter just needs the "glue" code connecting screens to providers to backend APIs.
