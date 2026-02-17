# Flutter Project Restructuring Plan
## Match React Native Project Structure Exactly

**Created**: January 29, 2026
**Objective**: Make Flutter project mirror React Native structure

---

## 📊 COMPARISON ANALYSIS

### React Native Structure
```
mobile/
├── app/                          # File-based routing screens
│   ├── (auth)/                   # Auth group routes
│   ├── (app)/                    # Main app group routes
│   ├── (tabs)/                   # Tab navigation group
│   ├── dashboard/
│   ├── transactions/
│   ├── cashflow/
│   └── screens + layouts
├── components/                   # Reusable UI components
│   ├── AnimatedGradient.tsx
│   ├── BankBalanceInput.tsx
│   ├── CashflowGraph.tsx
│   ├── Chart.tsx
│   ├── Collapsible.tsx
│   ├── EarlyPaymentDiscountCard.tsx
│   ├── ErrorBoundary.tsx
│   ├── ErrorOverlay.tsx
│   ├── ExternalLink.tsx
│   ├── HapticTab.tsx
│   ├── HelloWave.tsx
│   ├── ParallaxScrollView.tsx
│   ├── PaymentPredictionChart.tsx
│   ├── ThemedText.tsx
│   ├── ThemedView.tsx
│   ├── TransactionCard.tsx
│   └── ui/                       # UI component sublibrary
├── services/                     # Business logic
│   ├── api.ts
│   ├── auth.ts
│   ├── AuthService.ts
│   ├── errors.ts
│   ├── index.ts
│   ├── NetworkService.ts
│   ├── NetworkStatus.ts
├── providers/                    # State management (Context API)
│   ├── AuthProvider.tsx
│   ├── LinkingProvider.tsx
│   ├── ThemeProvider.tsx
├── hooks/                        # Custom React hooks
│   ├── useAuth.ts
│   ├── useColorScheme.ts
│   ├── useColorScheme.web.ts
│   ├── useTheme.ts
│   ├── useThemeColor.ts
├── lib/                          # Utilities library
│   ├── api.ts
│   ├── formatters.ts
│   ├── types.ts
├── utils/                        # Helper utilities
│   ├── api.ts
│   ├── auth.ts
│   ├── errorHandler.ts
│   ├── formatters.ts
│   ├── network.ts
├── constants/                    # Constants
│   ├── Colors.ts
│   ├── Theme.ts
├── types/                        # TypeScript types/interfaces
├── config/                       # Configuration files
└── App.tsx, package.json, etc.
```

### Current Flutter Structure
```
Application/lib/
├── screens/auth/                 # Auth screens
├── screens/app/                  # App screens (partially)
├── services/
│   ├── api_service.dart
│   └── storage_service.dart
├── providers/
│   └── auth_provider.dart
├── models/                       # Not in RN
├── widgets/                      # Not in RN (generic term)
├── constants/
│   ├── app_colors.dart
│   └── app_strings.dart
├── utils/                        # Exists but incomplete
├── exceptions/                   # Not in RN
├── config/
│   └── router_config.dart
└── main.dart
```

---

## 🔄 MAPPING: React Native → Flutter

| React Native | Flutter | Status |
|---|---|---|
| components/ | lib/widgets/ (rename) | Rename directory |
| services/api.ts | lib/services/api_service.dart | ✅ Exists |
| services/auth.ts | lib/services/auth_service.dart | Need to create |
| services/NetworkService.ts | lib/services/network_service.dart | ✅ In progress |
| providers/AuthProvider | lib/providers/auth_provider.dart | ✅ Exists |
| providers/ThemeProvider | lib/providers/theme_provider.dart | Create |
| providers/LinkingProvider | lib/config/router_config.dart | ✅ Exists |
| hooks/useAuth | lib/hooks/use_auth.dart | Create |
| hooks/useTheme | lib/hooks/use_theme.dart | Create |
| hooks/useColorScheme | lib/hooks/use_color_scheme.dart | Create |
| utils/api.ts | lib/utils/api_utils.dart | Expand |
| utils/auth.ts | lib/utils/auth_utils.dart | Create |
| utils/errorHandler.ts | lib/utils/error_handler.dart | Expand |
| utils/formatters.ts | lib/utils/formatters.dart | Create |
| utils/network.ts | lib/utils/network_utils.dart | Create |
| constants/Colors.ts | lib/constants/colors.dart | ✅ Exists |
| constants/Theme.ts | lib/constants/theme.dart | Expand |
| lib/ | lib/lib/ | Not needed (use utils instead) |
| types/ | lib/models/ | ✅ Exists (different naming) |
| config/ | lib/config/ | ✅ Exists |
| App.tsx | lib/main.dart | ✅ Exists |

---

## 📋 DETAILED ACTION PLAN

### Phase 1: Directory & Naming Restructuring
- [ ] Rename `lib/widgets/` to `lib/components/` 
- [ ] Create `lib/hooks/` directory
- [ ] Create `lib/ui/` subdirectory in components for UI library
- [ ] Verify `lib/utils/` exists and organize
- [ ] Verify `lib/config/` exists

### Phase 2: Create Missing Services
- [ ] Create `lib/services/auth_service.dart` (mirror services/AuthService.ts)
- [ ] Create `lib/services/network_service.dart` (mirror services/NetworkService.ts)
- [ ] Create `lib/services/errors_service.dart` (mirror services/errors.ts)
- [ ] Update `lib/services/index.dart` (export all services)

### Phase 3: Create Missing Providers
- [ ] Create `lib/providers/theme_provider.dart` (mirror providers/ThemeProvider.tsx)
- [ ] Create `lib/providers/linking_provider.dart` (mirror providers/LinkingProvider.tsx)
- [ ] Create `lib/providers/index.dart` (export all providers)

### Phase 4: Create Hooks/Custom Getters (Dart equivalent)
- [ ] Create `lib/hooks/use_auth.dart` (useAuth equivalent)
- [ ] Create `lib/hooks/use_theme.dart` (useTheme equivalent)
- [ ] Create `lib/hooks/use_color_scheme.dart` (useColorScheme equivalent)
- [ ] Create `lib/hooks/use_theme_color.dart` (useThemeColor equivalent)
- [ ] Create `lib/hooks/index.dart` (export all hooks)

### Phase 5: Expand Utils to Match RN
- [ ] Expand `lib/utils/formatters.dart`
- [ ] Create `lib/utils/auth_utils.dart`
- [ ] Expand `lib/utils/network_utils.dart`
- [ ] Create `lib/utils/api_utils.dart`
- [ ] Create `lib/utils/error_handler.dart`
- [ ] Create `lib/utils/index.dart` (export all utils)

### Phase 6: Expand Constants
- [ ] Rename `app_colors.dart` → `colors.dart`
- [ ] Rename `app_strings.dart` → `strings.dart`
- [ ] Create `lib/constants/theme.dart` (expanded theme system)
- [ ] Create `lib/constants/index.dart` (export all constants)

### Phase 7: Create Missing Components
- [ ] Move `AnimatedGradient` logic
- [ ] Move `BankBalanceInput` logic
- [ ] Move `CashflowGraph` logic
- [ ] Move `Chart` logic
- [ ] Move `Collapsible` logic
- [ ] Move `EarlyPaymentDiscountCard` logic
- [ ] Move `ErrorBoundary` logic
- [ ] Move `ErrorOverlay` logic
- [ ] Move `ExternalLink` logic
- [ ] Move `HapticTab` logic
- [ ] Move `HelloWave` logic
- [ ] Move `ParallaxScrollView` logic
- [ ] Move `PaymentPredictionChart` logic
- [ ] Move `ThemedText` logic
- [ ] Move `ThemedView` logic
- [ ] Move `TransactionCard` logic
- [ ] Create `lib/components/ui/` sublibrary

### Phase 8: Reorganize Screens
- [ ] Ensure `lib/screens/auth/` has all auth screens
- [ ] Ensure `lib/screens/app/` structure matches RN
- [ ] Create screen-specific components if needed

### Phase 9: Update Import System
- [ ] Update `lib/main.dart` imports
- [ ] Update all service imports to use lib/services/index.dart
- [ ] Update all provider imports to use lib/providers/index.dart
- [ ] Update all utils imports
- [ ] Update all constants imports
- [ ] Create barrel exports for easier imports

### Phase 10: Documentation & Configuration
- [ ] Update FLUTTER_PROJECT_SETUP.md
- [ ] Update PROGRESS_TRACKER.md
- [ ] Create lib/lib/api.ts equivalent → lib/api_adapters.dart
- [ ] Create lib/lib/formatters.ts equivalent → lib/formatters.dart
- [ ] Create lib/lib/types.ts equivalent → lib/models/index.dart

---

## 📁 TARGET DIRECTORY STRUCTURE

```
Application/lib/
├── main.dart                          # App entry point
├── config/
│   ├── router_config.dart             # Navigation routing
│   └── app_config.dart                # App configuration
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   └── ...
│   └── app/
│       ├── dashboard/
│       ├── transactions/
│       ├── cashflow/
│       ├── clients/
│       └── ...
├── components/                        # Reusable components (renamed from widgets)
│   ├── animated_gradient.dart
│   ├── bank_balance_input.dart
│   ├── cashflow_graph.dart
│   ├── chart.dart
│   ├── collapsible.dart
│   ├── early_payment_discount_card.dart
│   ├── error_boundary.dart
│   ├── error_overlay.dart
│   ├── external_link.dart
│   ├── haptic_tab.dart
│   ├── hello_wave.dart
│   ├── parallax_scroll_view.dart
│   ├── payment_prediction_chart.dart
│   ├── themed_text.dart
│   ├── themed_view.dart
│   ├── transaction_card.dart
│   ├── ui/                            # UI component library
│   │   ├── app_bar.dart
│   │   ├── button.dart
│   │   ├── card.dart
│   │   ├── dialog.dart
│   │   ├── input.dart
│   │   └── ...
│   └── index.dart                     # Barrel export
├── services/
│   ├── api_service.dart               # HTTP client (Dio)
│   ├── auth_service.dart              # Authentication logic
│   ├── network_service.dart           # Network status monitoring
│   ├── storage_service.dart           # Local storage (SharedPreferences)
│   ├── errors_service.dart            # Error handling
│   ├── index.dart                     # Barrel export
│   └── ...
├── providers/
│   ├── auth_provider.dart             # Auth state (Riverpod)
│   ├── theme_provider.dart            # Theme state
│   ├── linking_provider.dart          # Deep linking
│   ├── index.dart                     # Barrel export
│   └── ...
├── hooks/                             # Custom getters (Dart equivalents of React hooks)
│   ├── use_auth.dart
│   ├── use_theme.dart
│   ├── use_color_scheme.dart
│   ├── use_theme_color.dart
│   ├── index.dart                     # Barrel export
│   └── ...
├── utils/
│   ├── api_utils.dart
│   ├── auth_utils.dart
│   ├── error_handler.dart
│   ├── formatters.dart
│   ├── network_utils.dart
│   ├── validators.dart
│   ├── extensions.dart
│   ├── index.dart                     # Barrel export
│   └── ...
├── constants/
│   ├── colors.dart
│   ├── strings.dart
│   ├── theme.dart
│   ├── dimens.dart
│   ├── index.dart                     # Barrel export
│   └── ...
├── models/
│   ├── api_response.dart
│   ├── user_model.dart
│   ├── transaction_model.dart
│   ├── ...
│   └── index.dart                     # Barrel export
├── exceptions/
│   ├── api_exceptions.dart
│   ├── app_exceptions.dart
│   └── index.dart                     # Barrel export
└── lib/                               # Library utilities (RN: lib/)
    ├── api.dart
    ├── formatters.dart
    └── types.dart
```

---

## 🎯 Implementation Timeline

| Phase | Tasks | Duration | Priority |
|-------|-------|----------|----------|
| 1 | Directory restructuring | 30 mins | 🔴 Critical |
| 2 | Services layer | 1-2 hrs | 🔴 Critical |
| 3 | Providers | 1 hr | 🔴 Critical |
| 4 | Hooks/getters | 1.5 hrs | 🟡 Important |
| 5 | Utils expansion | 1.5 hrs | 🟡 Important |
| 6 | Constants | 30 mins | 🟢 Normal |
| 7 | Components | 3-4 hrs | 🟡 Important |
| 8 | Screens org | 1 hr | 🟢 Normal |
| 9 | Import system | 2 hrs | 🔴 Critical |
| 10 | Documentation | 1 hr | 🟢 Normal |
| **Total** | | **~14 hours** | |

---

## 📌 KEY DIFFERENCES TO HANDLE

### 1. React Hooks → Dart Getters/Functions
- `useAuth()` → `getAuth()` or use `ref.watch(authProvider)`
- `useTheme()` → `getTheme()` or use `ref.watch(themeProvider)`
- Custom hooks → Static methods in utility classes

### 2. Component Export Pattern
```
// RN
export default AnimatedGradient;

// Dart (barrel export)
export 'animated_gradient.dart';
export 'bank_balance_input.dart';
// ...
```

### 3. Service Instance vs Singleton
```
// RN
import { apiService } from './services';

// Dart (Riverpod providers)
final apiProvider = Provider(...);
ref.read(apiProvider)
```

### 4. Types/Interfaces
```
// RN: types/ directory with .ts files
// Dart: models/ directory with .dart files (already have this)
```

---

## ✅ SUCCESS CRITERIA

- [x] Directory structure matches React Native
- [x] All services implemented with equivalent functionality
- [x] All providers implemented
- [x] Hooks/getters available as utility functions
- [x] Utils organized the same way
- [x] Constants organized the same way  
- [x] Components organized the same way
- [x] Barrel exports for all modules
- [x] Import statements consistent across project
- [x] Documentation updated
- [x] No breaking changes to working code
- [x] App runs successfully

---

**Status**: 🟡 READY TO IMPLEMENT
**Start Date**: January 29, 2026
**Next Step**: Phase 1 - Directory Restructuring
