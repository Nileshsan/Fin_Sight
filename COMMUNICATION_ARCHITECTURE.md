# 🔄 Communication Architecture Comparison

## React Native: LIVE PRODUCTION ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                     REACT NATIVE APP                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐                                            │
│  │  Splash Screen   │                                            │
│  │  - No API calls  │                                            │
│  │  - Check token   │                                            │
│  └────────┬─────────┘                                            │
│           │ (if no token)                                        │
│           ↓                                                      │
│  ┌──────────────────┐                                            │
│  │  Login Screen    │                                            │
│  │  - Input email   │                                            │
│  │  - Input password│                                            │
│  └────────┬─────────┘                                            │
│           │                                                      │
│           │ POST /api/login/                                     │
│           │ { username, password }                               │
│           ↓                                                      │
│  ┌──────────────────────────┐                                   │
│  │   API Client             │                                    │
│  │   - NetworkService       │                                    │
│  │   - Axios instance       │                                    │
│  │   - Error handling       │                                    │
│  └────────┬─────────────────┘                                   │
│           │                                                      │
│           ↓ HTTP Request                                         │
│  ╔════════════════════════════════════════════════════════════╗ │
│  ║         DJANGO BACKEND (http://127.0.0.1:8000)             ║ │
│  ║                                                             ║ │
│  ║  POST /api/login/ → Response                               ║ │
│  ║  {                                                          ║ │
│  ║    "status": "success",                                     ║ │
│  ║    "data": {                                                ║ │
│  ║      "token": "eyJhbGc...",  ← JWT TOKEN                   ║ │
│  ║      "user": {                                              ║ │
│  ║        "id": 1,                                             ║ │
│  ║        "username": "john",                                  ║ │
│  ║        "company_id": 5,                                     ║ │
│  ║        "companies": [...]                                   ║ │
│  ║      }                                                       ║ │
│  ║    }                                                         ║ │
│  ║  }                                                           ║ │
│  ╚════════════════════════════════════════════════════════════╝ │
│           ↑                                                      │
│           │ Response                                             │
│           ↓                                                      │
│  ┌──────────────────────────────┐                              │
│  │  Store Auth Data             │                              │
│  │  - sessionToken in Storage   │                              │
│  │  - userInfo in Storage       │                              │
│  │  - Set API auth header       │                              │
│  └────────┬─────────────────────┘                              │
│           │                                                      │
│           ↓ (if model ready)                                     │
│  ┌──────────────────┐                                           │
│  │ Dashboard Screen │                                           │
│  │ - useEffect()    │                                           │
│  └────────┬─────────┘                                           │
│           │                                                      │
│           │ GET /api/payment-predictions/                       │
│           │ Authorization: Bearer {token}                       │
│           │                                                      │
│           │ GET /api/party-balances/                            │
│           │ Authorization: Bearer {token}                       │
│           │                                                      │
│           │ GET /api/bank-balance/                              │
│           │ Authorization: Bearer {token}                       │
│           ↓                                                      │
│  ╔════════════════════════════════════════════════════════════╗ │
│  ║         DJANGO BACKEND                                      ║ │
│  ║                                                             ║ │
│  ║  - Validates JWT token ✅                                  ║ │
│  ║  - Extracts user from token                                ║ │
│  ║  - Queries database                                        ║ │
│  ║  - Returns real financial data                             ║ │
│  ║                                                             ║ │
│  ║  Response: Payment predictions, party balances, etc        ║ │
│  ╚════════════════════════════════════════════════════════════╝ │
│           ↑                                                      │
│           │ Real Data                                            │
│           ↓                                                      │
│  ┌──────────────────────────────┐                              │
│  │ Display Dashboard            │                              │
│  │ - Revenue: ₹45.8L (REAL)     │                              │
│  │ - Cashflow: ₹12.4L (REAL)    │                              │
│  │ - On-time rate: 87% (REAL)   │                              │
│  │ - Predictions graph (REAL)   │                              │
│  └──────────────────────────────┘                              │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Flutter: STATIC ARCHITECTURE (CURRENT)

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLUTTER APP                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐                                            │
│  │  Splash Screen   │                                            │
│  │  - No API calls  │                                            │
│  │  - Hardcoded nav │                                            │
│  └────────┬─────────┘                                            │
│           │                                                      │
│           │ (after 2 sec delay)                                 │
│           ↓                                                      │
│  ┌──────────────────┐                                            │
│  │  Login Screen    │                                            │
│  │  - Input email   │                                            │
│  │  - Input password│                                            │
│  │  - TODO comment  │ ← NOT IMPLEMENTED                         │
│  │  - No API call   │ ✗ (should POST /api/login/)               │
│  └────────┬─────────┘                                            │
│           │                                                      │
│           │ context.go('/dashboard') ✗ NO AUTH CHECK            │
│           │ (bypasses authentication)                            │
│           ↓                                                      │
│  ┌──────────────────────┐                                        │
│  │ Dashboard Screen     │                                        │
│  │ (No API calls)       │                                        │
│  │                      │                                        │
│  │ ✗ Not using:         │                                        │
│  │   dashboardProvider  │                                        │
│  │   ApiService         │                                        │
│  │   AuthProvider       │                                        │
│  │                      │                                        │
│  │ ✓ Uses:              │                                        │
│  │   Hardcoded data     │                                        │
│  │   Mock widgets       │                                        │
│  └────────┬─────────────┘                                        │
│           │                                                      │
│           ↓                                                      │
│  ┌──────────────────────────────┐                               │
│  │ Display Mock Data            │                               │
│  │ - Revenue: ₹45.8L (HARDCODED)│                               │
│  │ - Cashflow: ₹12.4L (HARDCODED)│                              │
│  │ - On-time rate: 87% (CONST)  │                               │
│  │ - Mock alerts (STATIC)       │                               │
│  │                              │                               │
│  │ No connection to backend     │                               │
│  │ No real user data            │                               │
│  │ No real predictions          │                               │
│  └──────────────────────────────┘                               │
│                                                                   │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ INFRASTRUCTURE THAT EXISTS BUT NOT USED:             │       │
│  │                                                       │       │
│  │ ApiService (lib/services/api_service.dart)          │       │
│  │ - Dio HTTP client          ✓ Configured             │       │
│  │ - JWT Bearer token support ✓ Ready                  │       │
│  │ - Error handling           ✓ Implemented            │       │
│  │ - Interceptors             ✓ Setup                  │       │
│  │ - NO CALLS FROM SCREENS    ✗ Not used               │       │
│  │                                                       │       │
│  │ AuthProvider (lib/providers/auth_provider.dart)      │       │
│  │ - login() method           ✓ Defined                │       │
│  │ - Token management         ✓ Ready                  │       │
│  │ - Riverpod state           ✓ Setup                  │       │
│  │ - NOT CALLED BY LOGIN      ✗ Unused                 │       │
│  │                                                       │       │
│  │ AppConfig (lib/config/app_config.dart)              │       │
│  │ - Django URL configured    ✓ http://127.0.0.1:8000 │       │
│  │ - Never accessed           ✗ Not used               │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## What Needs to Happen: Flutter → Production

```
CURRENT STATE                           NEEDED CHANGES
────────────────────────────────────────────────────────────

Login Screen                    →       Login Screen
┌──────────────┐                       ┌──────────────┐
│ Input fields │                       │ Input fields │
│ Hardcoded nav│ ✗ NO AUTH             │ Call API ✓   │
│ Skip backend │                       │ Store JWT ✓  │
└──────────────┘                       └──────────────┘
                                              ↓
                                       authProvider.login()
                                              ↓
                                       API: POST /api/login/
                                              ↓
                                       Backend validates
                                              ↓
                                       JWT token received
                                              ↓
                                       Store in storage
                                              ↓
Dashboard Screen                →       Dashboard Screen
┌─────────────────┐                   ┌──────────────────┐
│ Mock stats      │ ✗ NO BACKEND       │ Real stats       │
│ ₹45.8L const    │                    │ From API ✓       │
│ ₹12.4L const    │                    │ dashboardProvider│
│ 87% const       │                    │ .watch()         │
│ No predictions  │                    │ Real predictions │
└─────────────────┘                    └──────────────────┘
                                              ↓
                                       apiService.getDashboard()
                                              ↓
                                       API: GET /api/dashboard/
                                       Header: Bearer {token}
                                              ↓
                                       Backend returns data
                                              ↓
                                       Display real data


Parties Screen                  →       Parties Screen
┌──────────────────┐                  ┌──────────────────┐
│ Mock party list  │ ✗ NO BACKEND      │ Real party list  │
│ Hard-coded data  │                   │ From API ✓       │
│ No real balances │                   │ partiesProvider  │
│ No payment dates │                   │ Real outstanding │
└──────────────────┘                   │ Real risk scores │
                                       │ Real payment dates
                                       └──────────────────┘
                                              ↓
                                       apiService.getParties()
                                              ↓
                                       API: GET /api/party-balances/
                                              ↓
                                       Backend returns party data
```

---

## Code Flow Comparison

### React Native Login
```typescript
// app/(auth)/login.tsx
const handleLogin = async () => {
  const response = await api.login(username, password);  ← API CALL ✓
  
  if (response.status === 'success') {
    const token = response.data?.token;
    
    await AsyncStorage.setItem('sessionToken', token);  ← STORE TOKEN
    await api.setAuthToken(token);                      ← SET HEADER
    
    const modelStatus = await api.checkModelStatus();   ← ANOTHER API CALL
    
    if (modelStatus.isReady) {
      router.replace('/(app)');                         ← NAVIGATE
    } else {
      router.replace('/(auth)/model-training');
    }
  }
}
```

### Flutter Login (Current)
```dart
// login_screen.dart
Future<void> _handleLogin() async {
  setState(() => _isLoading = true);
  
  try {
    // ✗ TODO: Call login provider here
    // await ref.read(authProvider.notifier).login(email, password);
    
    // For now, just navigate to dashboard
    if (mounted) {
      context.go('/dashboard');  ← NO AUTH! BYPASSES SECURITY!
    }
  } catch (e) {
    setState(() => _errorMessage = e.toString());
  }
}
```

### Flutter Login (What It Should Be)
```dart
// login_screen.dart - NEEDS THIS
Future<void> _handleLogin() async {
  setState(() => _isLoading = true);
  
  try {
    await ref.read(authProvider.notifier).login(  ← CALL PROVIDER ✓
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

---

## API Endpoints Being Called

### React Native (WORKING)
```
✅ POST   /api/login/                      (authentication)
✅ GET    /api/model/status/               (ML model check)
✅ GET    /api/payment-predictions/        (dashboard)
✅ GET    /api/payment-analysis-summary/   (dashboard)
✅ GET    /api/party-balances/             (parties)
✅ GET    /api/bank-balance/               (bank info)
✅ GET    /api/unpaid-sales/               (transactions)
✅ POST   /api/transactions/cashflow/...   (updates)
```

### Flutter (NOT CALLED)
```
❌ POST   /api/login/                      (exists, not called)
❌ GET    /api/dashboard/                  (exists, not called)
❌ GET    /api/parties/                    (exists, not called)
❌ GET    /api/cashflow/                   (exists, not called)
❌ GET    /api/transactions/               (exists, not called)
```

---

## JWT Token Flow

### React Native
```
1. POST /api/login/
2. ← Response: { token: "eyJ..." }
3. AsyncStorage.setItem('sessionToken', token)
4. NetworkService interceptor auto-adds:
   Authorization: Bearer eyJ...
5. All subsequent requests include JWT
6. Backend validates with @permission_classes([JWTAuth])
```

### Flutter (Should Be Same)
```
1. POST /api/login/
   ← Response: { token: "eyJ..." }
2. StorageService.setAccessToken(token)
   (should also set SharedPreferences)
3. ApiService Dio interceptor auto-adds:
   Authorization: Bearer eyJ...
4. All subsequent requests include JWT
5. Backend validates with @permission_classes([JWTAuth])
```

---

## Summary: Readiness Assessment

| Component | Status | React Native | Flutter |
|-----------|--------|--------------|---------|
| HTTP Client | ✅ | Axios | Dio |
| JWT Setup | ✅ | Bearer token | Bearer token |
| Token Storage | ✅ | AsyncStorage | SharedPreferences |
| Auth Provider | ✅ | Hooks | Riverpod |
| Login API | ✅ | Called | Not called ❌ |
| Dashboard | ✅ | Real data | Mock data ❌ |
| Error Handling | ✅ | Custom exceptions | Custom exceptions |
| Offline Support | ✅ | Network detection | Not used ❌ |
| **Overall** | - | **🟢 PRODUCTION** | **🟡 FRAMEWORK ONLY** |

---

## What the Backend Sees

### React Native Login Request ✅
```
POST http://127.0.0.1:8000/api/login/

{
  "username": "john",
  "password": "password123"
}

← Response 200 OK:
{
  "status": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "john",
      "email": "john@company.com",
      "company_id": 5
    }
  }
}
```

### Flutter Login Request ❌
```
NEVER SENT TO BACKEND

context.go('/dashboard') 
↑ Just navigates without authentication
```

### React Native Dashboard Request ✅
```
GET http://127.0.0.1:8000/api/payment-predictions/?company_id=5

Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json

← Response 200 OK:
{
  "status": "success",
  "data": [
    {
      "date": "2025-01-30",
      "expected": 45000.00,
      "best_case": 52000.00,
      "worst_case": 38000.00,
      "confidence": 0.95
    },
    ...
  ]
}
```

### Flutter Dashboard Request ❌
```
NEVER SENT TO BACKEND

Dashboard() renders with hardcoded values:
  - Total Receivables: ₹45.8L (const)
  - Expected Cash: ₹12.4L (const)
  - On-time Rate: 87% (const)
```

---

## Bottom Line

**React Native = Live & Connected**
- User enters email/password
- API validates credentials
- JWT token returned
- Stored in AsyncStorage
- All screens use real backend data
- Production-ready ✅

**Flutter = Beautiful But Empty**
- UI looks professional
- Screens are well-designed
- But everything is mock data
- Infrastructure exists but unused
- Like a car with no engine 🚗

**To Connect Flutter:** Wire login → provider → API → screens (2-3 days of work)
