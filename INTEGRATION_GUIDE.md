# 🔗 Quick Start: Connecting Flutter to Backend

## Current Status

**React Native:** ✅ Connected, working, production-ready  
**Flutter:** 🟡 Static UI with mock data - needs wiring

---

## What's Already Done in Flutter

### ✅ API Infrastructure
- `ApiService` - Full HTTP client (Dio) with JWT support
- `StorageService` - Token persistence via SharedPreferences
- `AuthProvider` - Riverpod state management for auth
- `AppConfig` - Backend URL configured (http://127.0.0.1:8000)
- Custom exceptions - ApiException, AuthenticationException, etc.

### ✅ Router Setup
- Splash → Login → Dashboard flow
- ShellRoute with bottom navigation
- All 9 screens defined and routed

### ❌ What's Missing
- Login screen not calling API
- Screens not using providers
- No actual backend data fetching

---

## Step-by-Step Integration (2-3 Hours)

### STEP 1: Fix Login Screen (15 minutes)

**File:** `lib/screens/auth/login_screen.dart`

**Current (Line 72):**
```dart
// TODO: Call login provider here
// await ref.read(authProvider.notifier).login(email, password);

// For now, just navigate to dashboard
if (mounted) {
  context.go('/dashboard');
}
```

**Change to:**
```dart
try {
  // Call the login provider
  await ref.read(authProvider.notifier).login(
    _emailController.text.trim(),
    _passwordController.text,
  );

  if (mounted) {
    // Navigation will happen automatically via auth listener
    context.go('/dashboard');
  }
} catch (e) {
  setState(() => _errorMessage = e.toString());
}
```

---

### STEP 2: Implement Login in AuthProvider (15 minutes)

**File:** `lib/providers/auth_provider.dart`

Find the `login` method (around line 75) and ensure it's implemented:

```dart
Future<void> login(String username, String password) async {
  state = state.copyWith(isLoading: true, error: null);
  
  try {
    // Call API login endpoint
    final response = await _apiService.post(
      '/api/login/',
      data: {
        'username': username,
        'password': password,
      },
    );

    // Extract token from response
    final token = response.data['token'] ?? response.data['access_token'];
    if (token == null) {
      throw Exception('No token in response');
    }

    // Parse user data
    final userData = response.data['user'];
    final user = UserModel.fromJson(userData);

    // Store token in storage
    _storageService.setAccessToken(token);
    _storageService.setUserData(jsonEncode(user.toJson()));

    // Update API client with token
    _apiService.setToken(token);

    // Update auth state
    state = state.copyWith(
      isAuthenticated: true,
      user: user,
      accessToken: token,
      isLoading: false,
      error: null,
    );
  } catch (e) {
    state = state.copyWith(
      error: e.toString(),
      isLoading: false,
    );
    rethrow;
  }
}
```

---

### STEP 3: Create Dashboard Provider (20 minutes)

**New File:** `lib/providers/dashboard_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class DashboardData {
  final double totalReceivables;
  final double expectedCash7d;
  final double expectedCash30d;
  final int onTimeRate;
  final double highRiskAmount;
  
  DashboardData({
    required this.totalReceivables,
    required this.expectedCash7d,
    required this.expectedCash30d,
    required this.onTimeRate,
    required this.highRiskAmount,
  });
}

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(baseUrl: 'http://127.0.0.1:8000');
});

// Dashboard data provider
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    // Call multiple endpoints to get dashboard data
    final [
      paymentPredictions,
      paymentAnalysisSummary,
      bankBalance,
    ] = await Future.wait([
      apiService.get('/api/payment-predictions/', queryParameters: {
        'company_id': 1, // TODO: Get from auth provider
        'days': 90,
      }),
      apiService.get('/api/payment-analysis-summary/', queryParameters: {
        'company_id': 1,
      }),
      apiService.get('/api/bank-balance/', queryParameters: {
        'company_id': 1,
      }),
    ]);

    // Parse responses
    final predictions = paymentPredictions.data ?? [];
    final summary = paymentAnalysisSummary.data ?? {};
    final bank = bankBalance.data ?? {};

    return DashboardData(
      totalReceivables: (summary['total_receivables'] ?? 0).toDouble(),
      expectedCash7d: (summary['expected_cash_7d'] ?? 0).toDouble(),
      expectedCash30d: (summary['expected_cash_30d'] ?? 0).toDouble(),
      onTimeRate: (summary['on_time_rate'] ?? 0).toInt(),
      highRiskAmount: (summary['high_risk_amount'] ?? 0).toDouble(),
    );
  } catch (e) {
    print('Dashboard error: $e');
    rethrow;
  }
});

// Refresh provider for pull-to-refresh
final dashboardRefreshProvider = FutureProvider.autoDispose<void>((ref) async {
  ref.invalidate(dashboardProvider);
  return ref.watch(dashboardProvider).whenData((_) => null);
});
```

---

### STEP 4: Update Dashboard Screen (15 minutes)

**File:** `lib/screens/app/dashboard_screen.dart`

**Find:** `class DashboardScreen extends ConsumerStatefulWidget`

**Replace the entire build method with:**

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final colors = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  
  // Watch dashboard provider
  final dashboardAsync = ref.watch(dashboardProvider);

  return Scaffold(
    appBar: AppBar(
      title: const Text('Dashboard'),
      elevation: 0,
      backgroundColor: colors.surface,
    ),
    body: dashboardAsync.when(
      // Loading state
      loading: () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ),
      ),
      
      // Error state
      error: (error, stack) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(dashboardProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      
      // Data state
      data: (dashboard) => RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(dashboardProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metric Cards with REAL DATA
              Text(
                'Financial Overview',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Total Receivables (REAL)
              _buildMetricCard(
                context: context,
                label: 'Total Receivables',
                value: '₹${(dashboard.totalReceivables / 100000).toStringAsFixed(1)}L',
                change: '+12.3%',
                isPositive: true,
                icon: Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 12),
              
              // Expected Cash (REAL)
              Row(
                children: [
                  Expanded(
                    child: _buildSmallMetricCard(
                      context: context,
                      label: 'Expected Cash (7d)',
                      value: '₹${(dashboard.expectedCash7d / 100000).toStringAsFixed(1)}L',
                      icon: Icons.calendar_today_rounded,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallMetricCard(
                      context: context,
                      label: 'On-time Rate',
                      value: '${dashboard.onTimeRate}%',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // High Risk (REAL)
              _buildSmallMetricCard(
                context: context,
                label: 'High-Risk Amount',
                value: '₹${(dashboard.highRiskAmount / 100000).toStringAsFixed(1)}L',
                icon: Icons.warning_rounded,
                color: Colors.orange,
              ),
              
              // Rest of your UI...
              const SizedBox(height: 24),
              Text(
                'Cashflow Projection (Next 90 days)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // ... graph placeholder
            ],
          ),
        ),
      ),
    ),
  );
}
```

---

### STEP 5: Create Other Providers (30 minutes)

**New File:** `lib/providers/parties_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final partiesProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    final response = await apiService.get(
      '/api/party-balances/',
      queryParameters: {
        'company_id': 1, // TODO: Get from auth
      },
    );
    
    return response.data ?? [];
  } catch (e) {
    print('Parties error: $e');
    rethrow;
  }
});
```

**New File:** `lib/providers/cashflow_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final cashflowProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    final response = await apiService.get(
      '/api/payment-predictions/',
      queryParameters: {
        'company_id': 1,
        'days': 90,
      },
    );
    
    return response.data ?? {};
  } catch (e) {
    print('Cashflow error: $e');
    rethrow;
  }
});
```

---

### STEP 6: Update Screens to Use Providers

**Pattern for each screen:**

```dart
// OLD (Mock Data)
Widget build(BuildContext context, WidgetRef ref) {
  return Scaffold(
    body: Column(
      children: [
        Text('₹45.8L'), // Hardcoded
      ],
    ),
  );
}

// NEW (Real Data)
Widget build(BuildContext context, WidgetRef ref) {
  final dataAsync = ref.watch(partiesProvider);
  
  return dataAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, _) => Center(child: Text('Error: $err')),
    data: (data) => Scaffold(
      body: Column(
        children: [
          // Display REAL data
          for (final item in data)
            ListTile(
              title: Text(item['name']),
              subtitle: Text('₹${item['balance']}'),
            ),
        ],
      ),
    ),
  );
}
```

---

## Testing the Connection

### Test 1: Check Backend is Running
```bash
curl http://127.0.0.1:8000/api/health/
# Should return: {"status": "healthy", "message": "API is running"}
```

### Test 2: Test Login Endpoint
```bash
curl -X POST http://127.0.0.1:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "john", "password": "password123"}'
# Should return: {"status": "success", "data": {"token": "...", "user": {...}}}
```

### Test 3: Test Dashboard Endpoint (with token)
```bash
curl http://127.0.0.1:8000/api/dashboard/ \
  -H "Authorization: Bearer {your_token_here}"
# Should return dashboard data
```

---

## What to Do Next

### Immediate (Today)
1. ✅ Fix login screen → call authProvider
2. ✅ Implement login in AuthProvider
3. ✅ Create dashboard provider
4. ✅ Update dashboard screen to use provider

### Short Term (Tomorrow)
5. ✅ Create parties, cashflow, discounts, email, AI providers
6. ✅ Update all app screens to use providers
7. ✅ Test each endpoint with real backend data

### Polish (2-3 Days)
8. ✅ Add error handling and retry logic
9. ✅ Add loading states for all screens
10. ✅ Add offline detection
11. ✅ Test end-to-end flow

---

## Common Issues & Solutions

### Issue: "Token not added to requests"
**Solution:** Ensure ApiService constructor initializes Dio with interceptors

### Issue: "401 Unauthorized"
**Solution:** Token not in storage. Check:
1. Login stored token correctly
2. ApiService retrieving token from storage
3. Dio interceptor adding Bearer prefix

### Issue: "Backend not found"
**Solution:** Check AppConfig has correct URL:
```dart
// Should be:
static const String djangoBaseUrl = 'http://127.0.0.1:8000';
```

### Issue: "CORS errors"
**Solution:** Add to Django CORS_ALLOWED_ORIGINS:
```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:8100",
    "http://127.0.0.1:8100",
]
```

---

## Expected Results After Integration

**Before:**
```
Splash (2s) → Login (no API) → Dashboard (₹45.8L hardcoded)
```

**After:**
```
Splash (2s) → Login (validates with backend) → Dashboard (real ₹X.XL from API)
```

**Data Flow:**
```
User enters credentials
    ↓
POST /api/login/
    ↓
JWT token returned
    ↓
Stored in SharedPreferences
    ↓
Dashboard screen loads
    ↓
GET /api/dashboard/ with Bearer token
    ↓
Real data displayed
```

---

## Verification Checklist

- [ ] Backend running on http://127.0.0.1:8000
- [ ] Login endpoint returns JWT token
- [ ] Flutter login screen calls authProvider.login()
- [ ] authProvider calls API service
- [ ] Token stored in storage
- [ ] Dashboard provider fetches real data
- [ ] Dashboard screen uses dashboardProvider
- [ ] Real financial data displayed (not ₹45.8L hardcoded)
- [ ] All 9 screens wired to appropriate providers
- [ ] Errors handled gracefully
- [ ] Pull-to-refresh works
- [ ] Token added to all authorized requests

✅ = Production Ready
