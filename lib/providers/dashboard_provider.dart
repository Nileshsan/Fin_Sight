import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/data_sync_service.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart';

/// Extended dashboard data combining all LIVE analyses
class DashboardData {
  final double totalReceivables;
  final double expectedCash7d;
  final double onTimeRate;
  final double highRiskAmount;
  final List<double> cashflowData; // 90-day projection
  final List<Map<String, dynamic>> topClients;
  // LIVE analysis data
  final CashflowResponse? cashflowAnalysis;
  final CategoriesResponse? categories;
  final DiscountsResponse? discounts;
  final EmailsResponse? emails;
  final String? generatedAt;
  // Payment Analysis Metrics
  final int totalPartiesAnalyzed;
  final int partiesWithPaymentPatterns;
  final double averagePaymentDelayDays;
  final double totalUnpaidSalesAmount;
  final List<Map<String, dynamic>> unpaidSalesList;
  // Parties data from backend
  final List<PartyData> parties;

  DashboardData({
    required this.totalReceivables,
    required this.expectedCash7d,
    required this.onTimeRate,
    required this.highRiskAmount,
    required this.cashflowData,
    required this.topClients,
    required this.parties,
    this.cashflowAnalysis,
    this.categories,
    this.discounts,
    this.emails,
    this.generatedAt,
    this.totalPartiesAnalyzed = 0,
    this.partiesWithPaymentPatterns = 0,
    this.averagePaymentDelayDays = 0.0,
    this.totalUnpaidSalesAmount = 0.0,
    this.unpaidSalesList = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalReceivables: (json['total_receivables'] ?? 0).toDouble(),
      expectedCash7d: (json['expected_cash_7d'] ?? 0).toDouble(),
      onTimeRate: (json['on_time_rate'] ?? 0).toDouble(),
      highRiskAmount: (json['high_risk_amount'] ?? 0).toDouble(),
      cashflowData: List<double>.from(
        (json['cashflow_90d'] as List?)?.map((x) => (x ?? 0).toDouble()) ?? [],
      ),
      topClients: List<Map<String, dynamic>>.from(
        (json['top_clients'] as List?) ?? [],
      ),
      parties: const [],
    );
  }

  /// Create from UnifiedDashboardResponse (LIVE data)
  factory DashboardData.fromUnifiedResponse(
    UnifiedDashboardResponse response,
  ) {
    // Extract top discounts for top_clients
    final topClients = response.discounts.discounts
        .take(5)
        .map((d) => {
              'name': d.party,
              'amount': (d.closingBalance ?? 0.0),
              'discount': (d.totalDiscount ?? 0.0),
              'email_ready': true,
            })
        .toList();

    // Calculate total from all predictions
    final predictedBalance = response.cashflow.predictions.isNotEmpty
        ? response.cashflow.predictions.last.predictedBalance
        : 0.0;

    final totalReceivables = response.discounts.summary['total_potential_discount'] ?? 0;

    // ===== PAYMENT ANALYSIS METRICS FROM LIVE DATA =====
    
    // Total parties analyzed: count all unique parties from categories
    final allCategoriesClients = <String>{};
    response.categories.categories.forEach((category, clients) {
      for (var client in clients) {
        allCategoriesClients.add(client.party);
      }
    });
    final totalPartiesAnalyzed = allCategoriesClients.length;

    // Parties with payment patterns: clients with recorded payment history (payment_count > 0)
    final partiesWithPatterns = <String>{};
    response.categories.categories.forEach((category, clients) {
      for (var client in clients) {
        if (client.paymentCount > 0) {
          partiesWithPatterns.add(client.party);
        }
      }
    });
    final partiesWithPaymentPatterns = partiesWithPatterns.length;

    // Average payment delay: average of all avg_payment_days from categories
    double totalPaymentDays = 0;
    int countWithDays = 0;
    response.categories.categories.forEach((category, clients) {
      for (var client in clients) {
        if (client.avgPaymentDays != null && client.avgPaymentDays! > 0) {
          totalPaymentDays += client.avgPaymentDays!;
          countWithDays++;
        }
      }
    });
    final averagePaymentDelayDays = countWithDays > 0 
      ? totalPaymentDays / countWithDays 
      : 0.0;

    // ====================================================================
    // COMPUTE REAL CASHFLOW FROM PARTY DATA & PAYING HABITS
    // ====================================================================
    // Use parties array to build accurate unpaid sales list and 90-day cashflow
    final unpaidSalesList = <Map<String, dynamic>>[];
    final daysPaymentMap = <int, double>{}; // Map of day -> amount expected that day

    // Initialize 90-day map with 0 for each day
    for (int day = 0; day < 90; day++) {
      daysPaymentMap[day] = 0.0;
    }

    // Process each party from parties array
    if (response.parties.isNotEmpty) {
      for (final party in response.parties) {
        // Only include parties with unpaid closing balance
        if (party.closingBalance > 0) {
          // Add to unpaid sales list
          unpaidSalesList.add({
            'party': party.partyName,
            'amount': party.closingBalance,
            'date': party.predictedPaymentDate ?? 'N/A',
            'daysRemaining': party.daysRemaining,
            'category': party.category,
            'discount_available': party.discountAmount,
            'paying_habit': party.avgPaymentDays,
          });

          // Add to cashflow map: project payment on daysRemaining day
          int paymentDay = party.daysRemaining;
          
          // Clamp to 0-89 range
          if (paymentDay < 0) paymentDay = 0; // Overdue, assume immediate payment
          if (paymentDay > 89) paymentDay = 89; // Beyond horizon, cap at day 89

          // Add this party's amount to that day's expected inflow
          daysPaymentMap[paymentDay] = (daysPaymentMap[paymentDay] ?? 0.0) + party.closingBalance;
        }
      }
    } else {
      // Fallback to discounts if parties not available
      for (final offer in response.discounts.discounts) {
        if (offer.closingBalance > 0) {
          unpaidSalesList.add({
            'party': offer.party,
            'amount': offer.closingBalance,
            'date': offer.expectedPaymentDate ?? 'N/A',
            'daysRemaining': offer.daysRemaining,
            'category': offer.category,
          });

          int paymentDay = offer.daysRemaining;
          if (paymentDay < 0) paymentDay = 0;
          if (paymentDay > 89) paymentDay = 89;
          daysPaymentMap[paymentDay] = (daysPaymentMap[paymentDay] ?? 0.0) + offer.closingBalance;
        }
      }
    }

    // Build 90-day cumulative cashflow array
    final cashflowData = <double>[];
    double cumulativeBalance = 0.0;
    for (int day = 0; day < 90; day++) {
      cumulativeBalance += daysPaymentMap[day] ?? 0.0;
      cashflowData.add(cumulativeBalance);
    }

    // Calculate expected cash in next 7 days from cashflow data
    double expectedCash7d = 0.0;
    if (cashflowData.isNotEmpty && cashflowData.length > 6) {
      // At day 6 (7th day), we have cumulative total of payments expected by then
      expectedCash7d = cashflowData[6];
    }

    // Total unpaid sales amount
    final totalUnpaidSalesAmount = unpaidSalesList.fold<double>(
      0.0,
      (sum, sale) => sum + (sale['amount'] as double? ?? 0.0),
    );

    // Sort unpaid sales by days remaining (ascending) for display
    unpaidSalesList.sort((a, b) => 
      (a['daysRemaining'] as int).compareTo(b['daysRemaining'] as int)
    );

    // Calculate on-time payment rate from party categories
    // Category A (Fast Payer) and B (Normal Payer) are considered on-time
    int onTimeCount = 0;
    int totalParties = 0;
    
    if (response.parties.isNotEmpty) {
      for (final party in response.parties) {
        if (party.category == 'A' || party.category == 'B') {
          onTimeCount++;
        }
        totalParties++;
      }
    } else {
      // Fallback: count from categories
      response.categories.categories.forEach((cat, clients) {
        if (cat == 'A' || cat == 'B') {
          onTimeCount += clients.length;
        }
        totalParties += clients.length;
      });
    }
    
    final onTimeRate = totalParties > 0 
      ? (onTimeCount / totalParties) * 100 
      : 75.0;

    return DashboardData(
      totalReceivables: (totalReceivables as num).toDouble(),
      expectedCash7d: expectedCash7d,
      onTimeRate: onTimeRate,
      highRiskAmount: (response.categories.categories['D']?.fold<double>(
              0,
              (sum, c) => sum) ??
          0), // D = outliers/risk
      cashflowData: cashflowData.isEmpty ? List.generate(90, (_) => 0.0) : cashflowData,
      topClients: topClients,
      parties: response.parties,
      cashflowAnalysis: response.cashflow,
      categories: response.categories,
      discounts: response.discounts,
      emails: response.emails,
      generatedAt: response.generatedAt,
      totalPartiesAnalyzed: totalPartiesAnalyzed,
      partiesWithPaymentPatterns: partiesWithPaymentPatterns,
      averagePaymentDelayDays: averagePaymentDelayDays,
      totalUnpaidSalesAmount: totalUnpaidSalesAmount,
      unpaidSalesList: unpaidSalesList,
    );
  }

  // DEPRECATED: Do not use stub() - always use real data from API
  // If data is not available, throw an error instead
  @Deprecated('Use real data from API. Stub data masks issues.')
  static DashboardData stub() {
    throw UnsupportedError(
        'Stub data is deprecated and should not be used. Always fetch real data from the API.\n'
        'If this error is thrown, check if the backend API is responding correctly.');
  }
}

// Provider for TransactionService
final transactionServiceProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TransactionService(apiService: apiService);
});

// Provider for CacheService
final cacheServiceProvider = Provider((ref) {
  return CacheService();
});

// Provider for DataSyncService
final dataSyncServiceProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return DataSyncService(
    apiService: apiService,
    cacheService: cacheService,
  );
});

// StateNotifier to manage dashboard refresh
class DashboardRefreshNotifier extends StateNotifier<bool> {
  DashboardRefreshNotifier() : super(false);

  void forceRefresh() {
    state = !state; // Toggle to trigger re-evaluation
  }

  void clearCache() async {
    final cacheService = CacheService();
    await cacheService.clearCache();
    state = !state; // Trigger re-evaluation
  }
}

// Provider for managing refresh state
final dashboardRefreshProvider = StateNotifierProvider<DashboardRefreshNotifier, bool>((ref) {
  return DashboardRefreshNotifier();
});

// Provider to fetch LIVE unified dashboard with intelligent caching
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  try {
    final transactionService = ref.watch(transactionServiceProvider);
    final cacheService = ref.watch(cacheServiceProvider);
    final authState = ref.watch(authProvider);
    
    // Watch refresh notifier to trigger re-fetch when refresh is requested
    ref.watch(dashboardRefreshProvider);

    // Debug logging
    try {
      print('dashboardProvider: isAuthenticated=${authState.isAuthenticated}, companyId=${authState.user?.companyId}');
    } catch (_) {}

    // If user is not authenticated, throw error - don't return fake data
    if (!authState.isAuthenticated) {
      try {
        print('dashboardProvider: not authenticated');
      } catch (_) {}
      throw Exception('User not authenticated. Cannot fetch dashboard data.');
    }

    try {
      // First, check if new data flag is set (new data added since last cache)
      final hasNewData = await cacheService.hasNewDataFlag();
      if (hasNewData) {
        print('dashboardProvider: New data flag detected - fetching fresh data');
        // Bypass cache and fetch fresh data
        final response = await transactionService.getUnifiedDashboard(days: 90);
        if (response.status == 'success') {
          await cacheService.saveDashboardData(response);
          await cacheService.clearNewDataFlag();  // Clear flag after processing
          return DashboardData.fromUnifiedResponse(response);
        }
      }

      // Check if cache is valid (not expired and no new data flag)
      final isCacheValid = await cacheService.isCacheValid();
      
      if (isCacheValid) {
        final cachedData = await cacheService.getCachedDashboard();
        if (cachedData != null) {
          print('dashboardProvider: Using valid cached data (6-hour cache, age < 360 min)');
          return DashboardData.fromUnifiedResponse(cachedData);
        }
      }

      // Cache expired or invalid - fetch LIVE unified dashboard with all 4 analyses
      print('dashboardProvider: Cache expired or invalid - fetching fresh data');
      final response = await transactionService.getUnifiedDashboard(days: 90);

      if (response.status == 'success') {
        // Cache the response for next time
        await cacheService.saveDashboardData(response);
        await cacheService.clearNewDataFlag();  // Ensure flag is clear after fresh fetch
        return DashboardData.fromUnifiedResponse(response);
      }

      try {
        print('dashboardProvider: API response status=${response.status}');
      } catch (_) {}

      // If fetch failed but we have older cached data, throw error with note about stale data
      final cachedData = await cacheService.getCachedDashboard();
      if (cachedData != null) {
        try {
          print('dashboardProvider: API failed, have stale cache but not using stub data');
        } catch (_) {}
        throw Exception('Failed to fetch fresh data. Stale cache available, but using real data only.');
      }

      // No data available - throw error
      throw Exception('Failed to fetch dashboard data. Status: ${response.status}');
    } catch (e) {
      try {
        print('[Dashboard] Error fetching dashboard: $e');
      } catch (_) {}

      // Try to use cached data on error, but log that it's not fresh
      try {
        final cachedData = await cacheService.getCachedDashboard();
        if (cachedData != null) {
          print('dashboardProvider: API call failed, using cached data as fallback (not real-time)');
          return DashboardData.fromUnifiedResponse(cachedData);
        }
      } catch (_) {}

      // No fallback available - throw error instead of returning stub/fake data
      rethrow;
    }
  } catch (e) {
    // Propagate error instead of returning stub data
    try {
      print('dashboardProvider: fatal error: $e');
    } catch (_) {}
    rethrow;
  }
});

// Uses `apiServiceProvider` from `auth_provider.dart`
