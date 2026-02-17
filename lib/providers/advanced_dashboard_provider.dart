import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/data_sync_service.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart';

/// Advanced dashboard refresh provider with smart caching
/// Use this to manually trigger dashboard refresh with control over caching behavior
final advancedDashboardRefreshProvider = StateNotifierProvider<
    AdvancedDashboardRefreshNotifier,
    AsyncValue<DashboardData>>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final authState = ref.watch(authProvider);

  return AdvancedDashboardRefreshNotifier(
    transactionService: transactionService,
    cacheService: cacheService,
    authState: authState,
  );
});

/// Advanced refresh logic with detailed control
class AdvancedDashboardRefreshNotifier
    extends StateNotifier<AsyncValue<DashboardData>> {
  final TransactionService transactionService;
  final CacheService cacheService;
  final AuthProviderState authState;
  final Logger logger = Logger();

  AdvancedDashboardRefreshNotifier({
    required this.transactionService,
    required this.cacheService,
    required this.authState,
  }) : super(const AsyncValue.loading());

  /// Refresh dashboard with option to ignore cache
  Future<void> refresh({
    bool ignoreCache = false,
    int days = 90,
  }) async {
    state = const AsyncValue.loading();

    try {
      if (!authState.isAuthenticated) {
        state = AsyncValue.data(DashboardData.stub());
        return;
      }

      // Try cache if not ignoring
      if (!ignoreCache) {
        final isRecent =
            await cacheService.isCacheRecent(withinMinutes: 30);
        if (isRecent) {
          final cached = await cacheService.getCachedDashboard();
          if (cached != null) {
            logger.i('Advanced refresh: using recent cache');
            state =
                AsyncValue.data(DashboardData.fromUnifiedResponse(cached));
            return;
          }
        }
      }

      // Fetch fresh data
      logger.i('Advanced refresh: fetching fresh data');
      final response =
          await transactionService.getUnifiedDashboard(days: days);

      if (response.status == 'success') {
        // Cache it
        await cacheService.saveDashboardData(response);
        state =
            AsyncValue.data(DashboardData.fromUnifiedResponse(response));
        logger.i('Advanced refresh: success, data cached');
      } else {
        // Try cache fallback
        final cached = await cacheService.getCachedDashboard();
        if (cached != null) {
          state =
              AsyncValue.data(DashboardData.fromUnifiedResponse(cached));
          logger.w('Advanced refresh: using stale cache as fallback');
        } else {
          state = AsyncValue.data(DashboardData.stub());
          logger.e('Advanced refresh: no cache available');
        }
      }
    } catch (e, st) {
      logger.e('Advanced refresh error: $e', error: e, stackTrace: st);

      // Try cache on error
      try {
        final cached = await cacheService.getCachedDashboard();
        if (cached != null) {
          state =
              AsyncValue.data(DashboardData.fromUnifiedResponse(cached));
          logger.i('Advanced refresh: using cache after error');
        } else {
          state = AsyncValue.data(DashboardData.stub());
        }
      } catch (_) {
        state = AsyncValue.data(DashboardData.stub());
      }
    }
  }

  /// Force refresh bypassing cache
  Future<void> forceRefresh({int days = 90}) async {
    await refresh(ignoreCache: true, days: days);
  }

  /// Soft refresh: only fetch if cache is old
  Future<void> softRefresh({int maxCacheAgeMinutes = 30}) async {
    if (await cacheService.isCacheRecent(
        withinMinutes: maxCacheAgeMinutes)) {
      // Cache is still good, don't fetch
      final cached = await cacheService.getCachedDashboard();
      if (cached != null) {
        state = AsyncValue.data(DashboardData.fromUnifiedResponse(cached));
      }
    } else {
      // Cache is old, fetch new
      await refresh(ignoreCache: false);
    }
  }

  /// Clear all data and cache
  Future<void> clearAll() async {
    await cacheService.clearCache();
    state = const AsyncValue.loading();
  }

  /// Get cache stats
  Future<Map<String, dynamic>> getCacheStats() async {
    return await cacheService.getCacheInfo();
  }
}
