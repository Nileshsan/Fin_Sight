import 'package:logger/logger.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'transaction_service.dart';

/// Data synchronization service
/// Manages syncing data with backend and deciding when to use cache vs fetching new data
class DataSyncService {
  final ApiService apiService;
  final CacheService cacheService;
  final Logger logger;

  // Sync configuration
  static const int defaultCacheValidityMinutes = 30;
  static const int minSyncIntervalSeconds = 10; // Prevent rapid requests

  DateTime? _lastSyncTime;

  DataSyncService({
    required this.apiService,
    required this.cacheService,
    Logger? logger,
  }) : logger = logger ?? Logger();

  /// Sync dashboard data: check if new data is available, use cache if valid
  /// Cache is used if:
  /// - Today's date hasn't changed since cache was created
  /// - Cache is less than 24 hours old
  /// - User didn't force refresh
  ///
  /// Returns SyncResult with data and cache status
  Future<SyncResult<UnifiedDashboardResponse>> syncDashboard({
    int days = 90,
    bool forceRefresh = false,
  }) async {
    try {
      logger.i('[SYNC] Dashboard sync request (forceRefresh=$forceRefresh)');
      
      // Check throttle
      if (!forceRefresh && !_canSync()) {
        logger.i('[SYNC] Throttled - using cached data');
        final cached = await cacheService.getCachedDashboard();
        if (cached != null) {
          return SyncResult.fromCache(cached);
        }
      }

      // NEW: Check if cache is valid (same day, not expired)
      if (!forceRefresh && await cacheService.isCacheValid()) {
        logger.i('[SYNC] Cache valid - serving from local storage');
        final cached = await cacheService.getCachedDashboard();
        if (cached != null) {
          return SyncResult.fromCache(cached);
        }
      }

      // Fetch new data from backend
      logger.i('[SYNC] Cache invalid/missing - fetching from backend');
      final response = await _fetchDashboardFromBackend(days: days);

      if (response.success && response.data != null) {
        // Cache the new data
        await cacheService.saveDashboardData(response.data!);
        _lastSyncTime = DateTime.now();
        logger.i('[SYNC] New data cached');
        return SyncResult.freshData(response.data!);
      } else {
        // Fallback to cache if fetch failed
        logger.w('[SYNC] Failed to fetch new data, falling back to cache');
        final cached = await cacheService.getCachedDashboard();
        if (cached != null) {
          return SyncResult.fromCache(cached);
        }
        return SyncResult.error(response.message ?? 'Unknown error');
      }
    } catch (e) {
      logger.e('[SYNC] Error in syncDashboard: $e');
      // Try to return cached data as fallback
      try {
        final cached = await cacheService.getCachedDashboard();
        if (cached != null) {
          return SyncResult.fromCache(cached);
        }
      } catch (_) {}
      return SyncResult.error(e.toString());
    }
  }

  /// Check if new data is available on backend (lightweight check)
  /// Returns the timestamp of latest data on server
  Future<DataVersionCheck> checkForNewData({
    required String serverDataVersion,
  }) async {
    try {
      final cacheTimestamp = await cacheService.getCacheTimestamp();
      if (cacheTimestamp == null) {
        return DataVersionCheck(
          hasNewData: true,
          reason: 'No cached data',
          serverVersion: serverDataVersion,
        );
      }

      // If server version differs from what we have, new data exists
      final lastCacheVersion = _getVersionFromTimestamp(cacheTimestamp);
      if (lastCacheVersion != serverDataVersion) {
        return DataVersionCheck(
          hasNewData: true,
          reason: 'Server version differs: $serverDataVersion vs $lastCacheVersion',
          serverVersion: serverDataVersion,
        );
      }

      return DataVersionCheck(
        hasNewData: false,
        reason: 'Cache is up-to-date',
        serverVersion: serverDataVersion,
      );
    } catch (e) {
      logger.e('Error checking for new data: $e');
      return DataVersionCheck(
        hasNewData: true,
        reason: 'Error checking version: $e',
        error: e.toString(),
      );
    }
  }

  /// Clear all cached data
  Future<void> clearAllData() async {
    try {
      await cacheService.clearCache();
      _lastSyncTime = null;
      logger.i('All cached data cleared');
    } catch (e) {
      logger.e('Error clearing data: $e');
    }
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final cacheInfo = await cacheService.getCacheInfo();
      return {
        'last_sync': _lastSyncTime?.toIso8601String(),
        'cache_info': cacheInfo,
        'cache_valid_for_minutes': defaultCacheValidityMinutes,
      };
    } catch (e) {
      logger.e('Error getting sync stats: $e');
      return {};
    }
  }

  // ============ Private Methods ============

  /// Check if enough time has passed to allow a new sync
  bool _canSync() {
    if (_lastSyncTime == null) return true;
    final elapsed = DateTime.now().difference(_lastSyncTime!);
    return elapsed.inSeconds >= minSyncIntervalSeconds;
  }

  /// Fetch dashboard data from backend
  Future<SyncApiResponse<UnifiedDashboardResponse>> _fetchDashboardFromBackend({
    required int days,
  }) async {
    try {
      // This would call the transaction service's getUnifiedDashboard
      // For now, returning a wrapped response
      final result = await _getUnifiedDashboardFromApi(days: days);
      // Return success if we got the response
      return SyncApiResponse.success(result);
    } catch (e) {
      return SyncApiResponse.error(e.toString());
    }
  }

  /// Get unified dashboard from API (to be implemented with actual service)
  Future<UnifiedDashboardResponse> _getUnifiedDashboardFromApi({
    required int days,
  }) async {
    // This is a placeholder - in real implementation, use TransactionService
    throw UnimplementedError('Implement with TransactionService.getUnifiedDashboard()');
  }

  /// Extract version from timestamp
  String _getVersionFromTimestamp(DateTime timestamp) {
    return timestamp.toIso8601String().split('T')[0];
  }
}

/// Result of a sync operation
class SyncResult<T> {
  final T? data;
  final bool isSuccess;
  final bool isFreshData;
  final String? errorMessage;
  final String source; // 'cache' or 'network'

  SyncResult({
    required this.data,
    required this.isSuccess,
    required this.isFreshData,
    this.errorMessage,
    required this.source,
  });

  factory SyncResult.freshData(T data) {
    return SyncResult(
      data: data,
      isSuccess: true,
      isFreshData: true,
      source: 'network',
    );
  }

  factory SyncResult.fromCache(T data) {
    return SyncResult(
      data: data,
      isSuccess: true,
      isFreshData: false,
      source: 'cache',
    );
  }

  factory SyncResult.error(String message) {
    return SyncResult(
      data: null,
      isSuccess: false,
      isFreshData: false,
      errorMessage: message,
      source: 'error',
    );
  }
}

/// Check result for whether new data is available
class DataVersionCheck {
  final bool hasNewData;
  final String reason;
  final String? serverVersion;
  final String? error;

  DataVersionCheck({
    required this.hasNewData,
    required this.reason,
    this.serverVersion,
    this.error,
  });
}

/// Wrapper for API response used in sync operations
class SyncApiResponse<T> {
  final T? data;
  final bool success;
  final String? message;
  final int? statusCode;
  final dynamic error;

  SyncApiResponse({
    this.data,
    required this.success,
    this.message,
    this.statusCode,
    this.error,
  });

  factory SyncApiResponse.success(T data) {
    return SyncApiResponse(
      data: data,
      success: true,
      statusCode: 200,
    );
  }

  factory SyncApiResponse.error(String message) {
    return SyncApiResponse(
      success: false,
      message: message,
      statusCode: 500,
    );
  }
}
