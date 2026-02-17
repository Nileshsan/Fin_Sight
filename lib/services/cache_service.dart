import 'dart:convert';
import 'package:logger/logger.dart';
import 'storage_service.dart';
import 'transaction_service.dart';

/// Cache service for managing application data caching
/// Strategy: 6-hour cache + new data flag detection
/// - Cache valid for 6 hours (360 minutes)
/// - When new data added, flag is set
/// - On app return, flag check triggers reprocessing
class CacheService {
  static const String _cacheKeyDashboard = 'dashboard_cache';
  static const String _cacheKeyTimestamp = 'dashboard_cache_timestamp';
  static const String _cacheKeyCacheDate = 'dashboard_cache_date';
  static const String _cacheKeyDataVersion = 'data_version';
  static const String _cacheKeyNewDataFlag = 'new_data_flag';  // NEW: flag for new data
  static const String _cacheKeyLastNewDataCheck = 'last_new_data_check';  // NEW: timestamp of last check
  static const int _cacheExpireMinutes = 360;  // 6 hours

  final StorageService storageService;
  final Logger logger;

  CacheService({
    StorageService? storageService,
    Logger? logger,
  })  : storageService = storageService ?? StorageService(),
        logger = logger ?? Logger();

  /// Save unified dashboard data to cache with metadata
  Future<void> saveDashboardData(UnifiedDashboardResponse response) async {
    try {
      final now = DateTime.now();
      
      // Create response map with cache metadata
      final responseMap = {
        'status': response.status,
        'company_id': response.companyId,
        'generated_at': response.generatedAt,
        'cashflow': _serializeCashflow(response.cashflow),
        'categories': _serializeCategories(response.categories),
        'discounts': _serializeDiscounts(response.discounts),
        'emails': _serializeEmails(response.emails),
      };

      // Save to storage with metadata
      final jsonString = jsonEncode(responseMap);
      await storageService.setString(_cacheKeyDashboard, jsonString);
      await storageService.setString(
        _cacheKeyTimestamp,
        now.toIso8601String(),
      );
      // NEW: Save today's date
      await storageService.setString(
        _cacheKeyCacheDate,
        now.toString().split(' ')[0],  // Store as YYYY-MM-DD
      );

      logger.i('[CACHE] Dashboard data cached successfully');
    } catch (e) {
      logger.e('[CACHE] Error caching dashboard data: $e');
    }
  }

  /// Get cached dashboard data
  Future<UnifiedDashboardResponse?> getCachedDashboard() async {
    try {
      final jsonString = storageService.getString(_cacheKeyDashboard);
      if (jsonString == null || jsonString.isEmpty) {
        logger.i('[CACHE] No cached dashboard found');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      logger.i('[CACHE] Retrieved dashboard from local cache');
      return UnifiedDashboardResponse.fromJson(json);
    } catch (e) {
      logger.e('[CACHE] Error retrieving cached dashboard: $e');
      return null;
    }
  }

  /// Get cache timestamp
  Future<DateTime?> getCacheTimestamp() async {
    try {
      final timestamp = storageService.getString(_cacheKeyTimestamp);
      if (timestamp == null || timestamp.isEmpty) {
        return null;
      }
      return DateTime.parse(timestamp);
    } catch (e) {
      logger.e('[CACHE] Error parsing cache timestamp: $e');
      return null;
    }
  }

  /// NEW: Check if cache is within 6-hour window
  /// Returns true only if:
  /// 1. Cache exists AND
  /// 2. Cache is not older than 6 hours (360 minutes) AND
  /// 3. New data flag is not set (no fresh data added since caching)
  Future<bool> isCacheValid({int maxAgeMinutes = _cacheExpireMinutes}) async {
    try {
      // Check if cache exists
      final timestamp = await getCacheTimestamp();
      if (timestamp == null) {
        logger.i('[CACHE] No cache - timestamp is null');
        return false;
      }

      // Check if cache is within age limit (6 hours)
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      if (difference.inMinutes >= maxAgeMinutes) {
        logger.i('[CACHE] Cache expired - age: ${difference.inMinutes} minutes (max: $maxAgeMinutes)');
        return false;
      }

      // Check if new data flag is set
      final newDataFlag = storageService.getBool(_cacheKeyNewDataFlag) ?? false;
      if (newDataFlag) {
        logger.i('[CACHE] New data flag detected - cache invalidated, forcing refresh');
        return false;
      }

      logger.i('[CACHE] Cache is valid (age: ${difference.inMinutes} min of $maxAgeMinutes)');
      return true;
    } catch (e) {
      logger.e('[CACHE] Error validating cache: $e');
      return false;
    }
  }

  /// Check if cache is recent (within specified minutes) - simpler version
  Future<bool> isCacheRecent({int withinMinutes = 30}) async {
    try {
      final timestamp = await getCacheTimestamp();
      if (timestamp == null) return false;

      final now = DateTime.now();
      final difference = now.difference(timestamp);
      return difference.inMinutes < withinMinutes;
    } catch (e) {
      logger.e('[CACHE] Error checking cache recency: $e');
      return false;
    }
  }

  /// NEW: Set flag indicating new data has been added
  /// Called by backend when new transactions/data is received
  /// Next time app loads, cache will be invalidated and data reprocessed
  Future<void> setNewDataFlag() async {
    try {
      await storageService.setBool(_cacheKeyNewDataFlag, true);
      await storageService.setString(
        _cacheKeyLastNewDataCheck,
        DateTime.now().toIso8601String(),
      );
      logger.i('[CACHE] New data flag set - cache will be refreshed on next load');
    } catch (e) {
      logger.e('[CACHE] Error setting new data flag: $e');
    }
  }

  /// NEW: Check if new data flag is set
  /// Used by dashboard provider to decide whether to reprocess data
  Future<bool> hasNewDataFlag() async {
    try {
      return storageService.getBool(_cacheKeyNewDataFlag) ?? false;
    } catch (e) {
      logger.e('[CACHE] Error checking new data flag: $e');
      return false;
    }
  }

  /// NEW: Clear new data flag after reprocessing
  /// Called by dashboard provider after successfully reprocessing data
  Future<void> clearNewDataFlag() async {
    try {
      await storageService.setBool(_cacheKeyNewDataFlag, false);
      logger.i('[CACHE] New data flag cleared - cache refreshed');
    } catch (e) {
      logger.e('[CACHE] Error clearing new data flag: $e');
    }
  }

  /// NEW: Get new data flag status with last check time
  /// Returns: {flag: bool, lastCheck: DateTime?}
  Future<Map<String, dynamic>> getNewDataFlagStatus() async {
    try {
      final flag = storageService.getBool(_cacheKeyNewDataFlag) ?? false;
      final lastCheckStr = storageService.getString(_cacheKeyLastNewDataCheck);
      final lastCheck = lastCheckStr != null ? DateTime.tryParse(lastCheckStr) : null;
      
      return {
        'flag': flag,
        'last_check': lastCheck,
        'has_flag': flag,
      };
    } catch (e) {
      logger.e('[CACHE] Error getting new data flag status: $e');
      return {'flag': false, 'last_check': null, 'has_flag': false};
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      await storageService.remove(_cacheKeyDashboard);
      await storageService.remove(_cacheKeyTimestamp);
      await storageService.remove(_cacheKeyCacheDate);
      await storageService.remove(_cacheKeyDataVersion);
      logger.i('All cache cleared');
    } catch (e) {
      logger.e('Error clearing cache: $e');
    }
  }

  /// Get cache size info
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final dashboard = storageService.getString(_cacheKeyDashboard) ?? '';
      final timestamp = await getCacheTimestamp();

      return {
        'size_bytes': dashboard.length,
        'timestamp': timestamp?.toIso8601String(),
        'is_recent': await isCacheRecent(),
        'has_data': dashboard.isNotEmpty,
      };
    } catch (e) {
      logger.e('Error getting cache info: $e');
      return {};
    }
  }

  // ============ Private Serialization Methods ============

  Map<String, dynamic> _serializeCashflow(CashflowResponse response) {
    return {
      'status': response.status,
      'predictions': response.predictions
          .map((p) => {
                'date': p.date,
                'predicted_balance': p.predictedBalance,
                'receipts': p.receipts,
                'expenses': p.expenses,
                'min_balance': p.minBalance,
                'max_balance': p.maxBalance,
                'confidence': p.confidence,
              })
          .toList(),
      'summary': response.summary,
    };
  }

  Map<String, dynamic> _serializeCategories(CategoriesResponse response) {
    final categoriesMap = <String, List<Map<String, dynamic>>>{};
    for (final entry in response.categories.entries) {
      categoriesMap[entry.key] = entry.value
          .map((c) => {
                'party': c.party,
                'avg_payment_days': c.avgPaymentDays,
                'discount': c.discount,
                'payment_count': c.paymentCount,
                'reliability': c.reliability,
                'category': c.category,
              })
          .toList();
    }

    return {
      'status': response.status,
      'categories': categoriesMap,
      'summary': response.summary,
    };
  }

  Map<String, dynamic> _serializeDiscounts(DiscountsResponse response) {
    return {
      'status': response.status,
      'discounts': response.discounts
          .map((d) => {
                'party': d.party,
                'sales_amount': d.salesAmount,
                'closing_balance': d.closingBalance,
                'expected_payment_date': d.expectedPaymentDate,
                'days_remaining': d.daysRemaining,
                'category': d.category,
                'category_discount': d.categoryDiscount,
                'time_value_discount': d.timeValueDiscount,
                'total_discount': d.totalDiscount,
                'discount_amount': d.discountAmount,
                'amount_if_paid_today': d.amountIfPaidToday,
                'email_subject': d.emailSubject,
                'client_email': d.clientEmail,
              })
          .toList(),
      'summary': response.summary,
    };
  }

  Map<String, dynamic> _serializeEmails(EmailsResponse response) {
    return {
      'status': response.status,
      'emails': response.emails.map((e) => e.toJson()).toList(),
      'summary': response.summary,
    };
  }
}
