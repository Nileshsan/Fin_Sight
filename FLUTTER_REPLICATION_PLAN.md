# Flutter App Replication Plan

## React Native → Flutter Mapping

### 🔐 AUTH FLOW
```
React Native                          Flutter
(auth)/splash.tsx          →   screens/auth/splash_screen.dart
(auth)/login.tsx           →   screens/auth/login_screen.dart
(auth)/api-token.tsx       →   screens/auth/api_token_screen.dart
(auth)/model-training.tsx  →   screens/auth/model_training_screen.dart
```

### 📱 APP SCREENS
```
React Native                          Flutter
(app)/dashboard/           →   screens/app/dashboard/dashboard_screen.dart
(app)/transactions/        →   screens/app/transactions/transactions_screen.dart
(app)/cashflow/            →   screens/app/cashflow/cashflow_screen.dart
(app)/clients/             →   screens/app/clients/clients_screen.dart
(app)/profile/             →   screens/app/profile/profile_screen.dart
(app)/settings/            →   screens/app/settings/settings_screen.dart
(app)/system/              →   screens/app/system/system_screen.dart
```

### 🧩 COMPONENTS
```
React Native               Flutter
AnimatedGradient          components/ui/animated_gradient.dart
Chart                     components/ui/chart.dart
Transaction Card          components/ui/transaction_card.dart
Bank Balance Input        components/ui/bank_balance_input.dart
Cashflow Graph            components/ui/cashflow_graph.dart
```

### 📊 MODELS NEEDED
- User Model
- Dashboard Data
- Transaction Model
- Cashflow Data
- Party Balance
- Bank Balance
- API Response Wrapper

### 🔧 SERVICES NEEDED
- API Service (with login, dashboard, transactions, cashflow endpoints)
- Storage Service (AsyncStorage → SharedPreferences)
- Auth Service (token management)

### 🎯 PROVIDERS NEEDED
- Auth Provider
- Dashboard Provider
- Transactions Provider
- Cashflow Provider
- Clients Provider

---

## Implementation Priority

### ✅ PHASE 1: Core Setup (Already Done)
- ✅ Services layer
- ✅ Providers layer
- ✅ Utils & constants
- ✅ Auth service & provider

### 📝 PHASE 2: Create Screens (NOW)
1. **Auth Screens** (3 files)
   - Splash screen with animations
   - Login screen with form validation
   - API token screen

2. **Dashboard Screen** (1 file)
   - Stats cards
   - Charts
   - Refresh functionality

3. **Transaction Screens** (2 files)
   - Transactions list
   - Transaction detail

4. **Cashflow Screen** (1 file)
   - Cashflow graph
   - Forecast data

5. **Clients Screen** (1 file)
   - Client list
   - Client balance

### 📚 PHASE 3: Supporting Components
- Animated gradient
- Charts
- Cards
- Graphs

### 🔗 PHASE 4: Routing Integration
- Update router config
- Deep linking

---

## Technology Mapping

| React Native | Flutter |
|---|---|
| React | Flutter |
| Expo Router | GoRouter |
| AsyncStorage | SharedPreferences |
| React Context | Riverpod |
| Axios | Dio |
| React Native Gesture Handler | Gesture Detector |
| Animated API | Flutter Animation |
| LinearGradient | LinearGradient (flutter_gradient) |
| Ionicons | Ionicons (cupertino_icons) |

---

## Screen Breakdown

### Auth Screens (3)
1. **Splash Screen**
   - Animated logo with scale/rotation/opacity
   - Loading animation
   - Auto-navigate to login or dashboard
   - Duration: 3-4 seconds

2. **Login Screen**
   - Email/username input
   - Password input
   - Remember me toggle
   - Login button with loading state
   - Error handling
   - Form validation

3. **API Token Screen**
   - Token input
   - API configuration
   - Testing connection

### App Screens (7)
1. **Dashboard Screen**
   - Stat cards (Revenue, Cash Flow, Expenses, Profit Margin)
   - Charts/Graphs
   - Period selector (Week, Month, Year)
   - Refresh control
   - Error handling
   - Loading state

2. **Transactions Screen**
   - List of transactions
   - Transaction filters
   - Search functionality
   - Pull to refresh
   - Transaction detail page

3. **Cashflow Screen**
   - Cashflow graph
   - Forecast data
   - Period view selector
   - Inflow/Outflow breakdown

4. **Clients Screen**
   - Client list
   - Client balance info
   - Search
   - Filter options

5. **Profile Screen**
   - User information
   - Profile editing
   - Password change

6. **Settings Screen**
   - Theme settings
   - Notification settings
   - Logout

7. **System Screen**
   - System information
   - App version
   - Debug info

---

## Next Steps

1. Create all screen files
2. Implement UI layouts (no data initially)
3. Integrate with providers
4. Add API calls
5. Add animations
6. Test end-to-end flow

