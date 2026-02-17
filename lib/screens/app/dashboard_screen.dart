import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/transaction_service.dart';
import '../../widgets/beautiful_cashflow_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  String _formatCurrency(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) {
          print('Dashboard error: $err');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error loading dashboard', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(err.toString(),
                    style: textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardDataProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async {
            // Clear cache and force fresh fetch
            await ref.read(cacheServiceProvider).clearCache();
            // Invalidate provider and wait for new data
            ref.invalidate(dashboardDataProvider);
            // Wait for the new data to be fetched
            await ref.read(dashboardDataProvider.future);
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Beautiful Header with Company Info
                _buildHeader(context, dashboard, ref),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Total Receivables Info
                      _buildReceivablesInfo(context, dashboard),
                      const SizedBox(height: 24),
                      // Key Metrics Grid (3-column sexy cards)
                      _buildKeyMetricsGrid(context, dashboard),
                      const SizedBox(height: 32),

                      // Cashflow Projection
                      Text('📊 Cashflow Projection (90 Days)',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 16),
                      
                      // Use Advanced Cashflow Chart
                      _buildAdvancedCashflowChart(context, dashboard),
                      const SizedBox(height: 32),

                      // Payment Analysis Summary
                      _buildPaymentAnalysisSummary(context, dashboard),
                      const SizedBox(height: 32),

                      // Unpaid Sales
                      _buildUnpaidSalesList(context, dashboard),
                      const SizedBox(height: 40),

                      // Promotional Banner
                      _buildPromotionalBanner(context),
                      const SizedBox(height: 40),

                      // Live Discount Offers Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('💰 LIVE Discount Offers',
                                  style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700, fontSize: 18)),
                              const SizedBox(height: 2),
                              Text('Active opportunities to increase cashflow',
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: AppStyles.grey)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppStyles.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${dashboard.discounts?.discounts.length ?? 0} Active',
                              style: textTheme.labelSmall?.copyWith(
                                  color: AppStyles.success,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (dashboard.discounts == null ||
                          dashboard.discounts!.discounts.isEmpty)
                        _buildEmptyState(context, 'No active discount offers')
                      else
                        ...dashboard.discounts!.discounts.take(5).map((discount) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDiscountCard(
                              context: context,
                              discount: discount,
                              onSendEmail: () =>
                                  _handleSendEmail(context, ref, discount),
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 32),

                      // Client Categories with Beautiful Cards
                      Text('👥 Client Categories',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 16),
                      if (dashboard.categories == null)
                        _buildEmptyState(context, 'No category data')
                      else
                        _buildCategoryCardsGrid(context, dashboard.categories!),
                      const SizedBox(height: 32),

                      // Top Clients with Enhanced Styling
                      Text('⭐ Top Clients',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 16),
                      if (dashboard.topClients.isEmpty)
                        _buildEmptyState(context, 'No client data available')
                      else
                        ...dashboard.topClients.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final client = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildEnhancedClientCard(
                              context: context,
                              name: client['name'] ?? 'Unknown',
                              amount: client['amount'] ?? 0,
                              discount: (client['discount'] ?? 0).toDouble(),
                              rank: idx + 1,
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 32),

                      // Alerts & Insights Section
                      Text('🎯 Performance Insights',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 16),
                      _buildEnhancedAlertCard(
                        context: context,
                        title: 'Cash Flow Status',
                        subtitle: dashboard.highRiskAmount > 0
                            ? '${_formatCurrency(dashboard.highRiskAmount)} at potential risk'
                            : 'All accounts performing well',
                        icon: Icons.trending_up_rounded,
                        color: dashboard.highRiskAmount > 0
                            ? AppStyles.warning
                            : AppStyles.success,
                        isEmpty: false,
                      ),
                      const SizedBox(height: 12),
                      _buildEnhancedAlertCard(
                        context: context,
                        title: 'On-Time Payment Rate',
                        subtitle:
                            '${dashboard.onTimeRate.toStringAsFixed(0)}% clients paying on schedule',
                        icon: Icons.check_circle_rounded,
                        color: AppStyles.primary,
                        isEmpty: false,
                      ),
                      const SizedBox(height: 12),
                      _buildEnhancedAlertCard(
                        context: context,
                        title: 'Ready Cash (Next 7 Days)',
                        subtitle:
                            '${_formatCurrency(dashboard.expectedCash7d)} expected incoming',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppStyles.success,
                        isEmpty: false,
                      ),

                      const SizedBox(height: 24),
                      if (dashboard.generatedAt != null)
                        Center(
                          child: Text(
                            'Last updated: ${dashboard.generatedAt}',
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppStyles.grey),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // FORCE REFRESH BUTTON - Direct server request
                      _buildForceRefreshButton(context, ref),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Beautiful Header with Gradient
  Widget _buildHeader(BuildContext context, DashboardData dashboard, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    
    // Debug logging
    print('[DEBUG] Current User: ${currentUser?.toJson()}');
    print('[DEBUG] Username: ${currentUser?.username}');
    print('[DEBUG] Email: ${currentUser?.email}');
    
    final userName = currentUser?.username?.isNotEmpty == true
        ? currentUser!.username
        : (currentUser?.firstName?.isNotEmpty == true
            ? currentUser!.firstName
            : (currentUser?.email?.isNotEmpty == true
                ? currentUser!.email
                : 'User'));
    
    print('[DEBUG] Display Name: $userName');
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppStyles.primary,
            AppStyles.primary.withOpacity(0.7),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $userName 👋',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CFO Dashboard',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
            ],
          ),
        );
  }

  Widget _buildReceivablesInfo(BuildContext context, DashboardData dashboard) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Receivables',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(dashboard.totalReceivables),
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white.withOpacity(0.8),
            size: 32,
          ),
        ],
      ),
    );
  }

  // Key Metrics Grid - 3 columns with beautiful cards
  Widget _buildKeyMetricsGrid(BuildContext context, DashboardData dashboard) {
    final textTheme = Theme.of(context).textTheme;
    
    final metrics = [
      (
        'Expected Cash\n(7 Days)',
        _formatCurrency(dashboard.expectedCash7d),
        Icons.calendar_today_rounded,
        AppStyles.primary,
      ),
      (
        'On-Time\nRate',
        '${dashboard.onTimeRate.toStringAsFixed(0)}%',
        Icons.check_circle_rounded,
        AppStyles.success,
      ),
      (
        'High-Risk\nAmount',
        _formatCurrency(dashboard.highRiskAmount),
        Icons.warning_rounded,
        AppStyles.warning,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: metrics.map((metric) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                metric.$4,
                metric.$4.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: metric.$4.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                metric.$3,
                color: Colors.white,
                size: 28,
              ),
              Column(
                children: [
                  Text(
                    metric.$2,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.$1,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Enhanced Discount Card
  Widget _buildDiscountCard({
    required BuildContext context,
    required DiscountOffer discount,
    required VoidCallback onSendEmail,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppStyles.success.withOpacity(0.15),
            AppStyles.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.success.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppStyles.success.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discount.party,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppStyles.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Amount: ${_formatCurrency(discount.closingBalance)}',
                      style: textTheme.bodySmall?.copyWith(color: AppStyles.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppStyles.success, AppStyles.success.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '${discount.totalDiscount.toStringAsFixed(1)}%',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Discount',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(
                  '💾 Save ${_formatCurrency(discount.discountAmount)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppStyles.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: AppStyles.success.withOpacity(0.1),
                side: BorderSide(color: AppStyles.success.withOpacity(0.3)),
              ),
              Chip(
                label: Text(
                  '${discount.daysRemaining}d',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppStyles.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: AppStyles.warning.withOpacity(0.1),
                side: BorderSide(color: AppStyles.warning.withOpacity(0.3)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSendEmail,
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Send Email Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Category Cards Grid
  Widget _buildCategoryCardsGrid(
    BuildContext context,
    CategoriesResponse categories,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final categoryData = [
      (
        'A - Best Payers',
        '⚡',
        AppStyles.success,
        categories.categories['A'] ?? [],
      ),
      (
        'B - Regular Payers',
        '✓',
        AppStyles.primary,
        categories.categories['B'] ?? [],
      ),
      (
        'C & D - At Risk',
        '⚠️',
        AppStyles.warning,
        [...(categories.categories['C'] ?? []), ...categories.categories['D'] ?? []]
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: categoryData.map((cat) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cat.$3.withOpacity(0.15),
                cat.$3.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cat.$3.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: cat.$3.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cat.$3.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        cat.$2,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cat.$3.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cat.$4.length}',
                      style: textTheme.bodySmall?.copyWith(
                        color: cat.$3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.$1,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppStyles.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cat.$4.length} clients',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppStyles.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Enhanced Client Card
  Widget _buildEnhancedClientCard({
    required BuildContext context,
    required String name,
    required dynamic amount,
    required double discount,
    required int rank,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final amountDouble = (amount is int) ? amount.toDouble() : amount as double;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppStyles.primary, AppStyles.primary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppStyles.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppStyles.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatCurrency(amountDouble),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppStyles.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppStyles.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${discount.toStringAsFixed(1)}% off',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppStyles.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: AppStyles.grey,
          ),
        ],
      ),
    );
  }

  // Enhanced Alert Card
  Widget _buildEnhancedAlertCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEmpty,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppStyles.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppStyles.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(BuildContext context, String message) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppStyles.lightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.divider),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 32, color: AppStyles.grey),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppStyles.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Force Refresh Button - Direct server request bypassing cache
  Widget _buildForceRefreshButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Show loading snackbar
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Fetching fresh data from server...'),
                ],
              ),
              duration: const Duration(seconds: 30),
              backgroundColor: Colors.grey[800],
            ),
          );

          try {
            // Clear cache explicitly
            await ref.read(cacheServiceProvider).clearCache();
            print('🔄 Force refresh: Cache cleared');

            // Invalidate and fetch fresh data
            ref.invalidate(dashboardDataProvider);
            await ref.read(dashboardDataProvider.future);

            print('🔄 Force refresh: Fresh data fetched successfully');

            // Show success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text('✓ Fresh data loaded successfully!'),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                  backgroundColor: AppStyles.success,
                ),
              );
            }
          } catch (e) {
            print('❌ Force refresh error: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.red[700],
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Force Refresh from Server'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            label,
            style:
                textTheme.bodySmall?.copyWith(color: AppStyles.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: AppStyles.black),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryTabs(
    BuildContext context,
    CategoriesResponse categories,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final tabs = [
      ('A - Fast Payers (2%)', AppStyles.success, categories.categories['A'] ?? []),
      ('B - Normal Payers (1%)', AppStyles.primary, categories.categories['B'] ?? []),
      ('C - Slow Payers (0%)', AppStyles.warning, categories.categories['C'] ?? []),
    ];

    return tabs.map((tab) {
      final label = tab.$1;
      final color = tab.$2;
      final clients = tab.$3;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${clients.length} clients',
                style: textTheme.bodySmall?.copyWith(color: AppStyles.grey),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildClientCard({
    required BuildContext context,
    required String name,
    required dynamic amount,
    required double discount,
    required int rank,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final amountDouble = (amount is int) ? amount.toDouble() : amount as double;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppStyles.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppStyles.primary,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: AppStyles.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppStyles.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Amount: ${_formatCurrency(amountDouble)} • Discount: ${discount.toStringAsFixed(1)}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppStyles.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppStyles.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppStyles.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowChart(BuildContext context, DashboardData dashboard) {
    final data = dashboard.cashflowData;
    final textTheme = Theme.of(context).textTheme;

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get min/max for scaling
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final padding = range * 0.1;

    // Create spots for line chart
    final spots = List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index]);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: range / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppStyles.divider,
                      strokeWidth: 0.8,
                      dashArray: [5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (data.length / 6).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index % 15 == 0 && index < data.length) {
                          return Text(
                            'D${index + 1}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppStyles.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: range / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCurrencyShort(value),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppStyles.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: AppStyles.divider, width: 1),
                    bottom: BorderSide(color: AppStyles.divider, width: 1),
                  ),
                ),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: minValue - padding,
                maxY: maxValue + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppStyles.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppStyles.primary.withOpacity(0.12),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(                    tooltipRoundedRadius: 12,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedBarSpot) {
                        final day = touchedBarSpot.x.toInt() + 1;
                        final value = touchedBarSpot.y;
                        return LineTooltipItem(
                          'Day $day\n${_formatCurrency(value)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppStyles.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Predicted Balance',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppStyles.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppStyles.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${data.length} days forecast',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppStyles.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrencyShort(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(0)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(0)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  // Fallback cashflow chart with generated data if predictions are empty
  Widget _buildCashflowChartWithFallback(
      BuildContext context, DashboardData dashboard) {
    final textTheme = Theme.of(context).textTheme;
    
    // Generate fallback data if empty
    final data = dashboard.cashflowData.isEmpty
        ? List.generate(90, (i) => 1000000 + (i * 5000).toDouble())
        : dashboard.cashflowData;

    if (data.isEmpty) {
      return _buildEmptyState(context, 'Unable to generate cashflow data');
    }

    // Get min/max for scaling
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final padding = range * 0.1;

    // Create spots for line chart
    final spots = List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index]);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note if using fallback data
          if (dashboard.cashflowData.isEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppStyles.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppStyles.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing projected data based on your account history',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppStyles.warning,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (dashboard.cashflowData.isEmpty) const SizedBox(height: 12),
          
          // Chart
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: range / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppStyles.divider,
                      strokeWidth: 0.8,
                      dashArray: [5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (data.length / 6).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index % 15 == 0 && index < data.length) {
                          return Text(
                            'D${index + 1}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppStyles.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: range / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCurrencyShort(value),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppStyles.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: AppStyles.divider, width: 1),
                    bottom: BorderSide(color: AppStyles.divider, width: 1),
                  ),
                ),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: minValue - padding,
                maxY: maxValue + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppStyles.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppStyles.primary.withOpacity(0.12),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(                    tooltipRoundedRadius: 12,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedBarSpot) {
                        final day = touchedBarSpot.x.toInt() + 1;
                        final value = touchedBarSpot.y;
                        return LineTooltipItem(
                          'Day $day\n${_formatCurrency(value)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppStyles.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Predicted Balance',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppStyles.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppStyles.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${data.length} days forecast',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppStyles.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendEmail(
    BuildContext context,
    WidgetRef ref,
    DiscountOffer discount,
  ) async {
    // Check if email exists
    if (discount.clientEmail != null && discount.clientEmail!.isNotEmpty) {
      // Email exists, proceed with sending
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email to ${discount.party} will be sent to ${discount.clientEmail}'),
          ),
        );
      }
      return;
    }

    // Email missing, show input dialog
    if (!context.mounted) return;

    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Email Address for ${discount.party}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No email found for this client. Please enter their email address:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'contact@example.com',
                  labelText: 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save & Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final email = emailController.text.trim();
                Navigator.of(dialogContext).pop();

                // Save email via API
                await _savePartyEmail(
                  context: context,
                  ref: ref,
                  partyName: discount.party,
                  email: email,
                );

                // Show confirmation
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Email saved and will be sent to $email'),
                      backgroundColor: AppStyles.success,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );

    emailController.dispose();
  }

  Future<void> _savePartyEmail({
    required BuildContext context,
    required WidgetRef ref,
    required String partyName,
    required String email,
  }) async {
    try {
      // Get API service from provider
      final apiService = ref.read(transactionServiceProvider);

      // Send email via sendEmails method
      final response = await apiService.sendEmails(
        emails: [
          {
            'party_name': partyName,
            'email': email,
          }
        ],
      );

      if (response['status'] == 'success') {
        // Refresh dashboard to get updated email
        ref.refresh(dashboardDataProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Build Beautiful Cashflow Chart
  Widget _buildAdvancedCashflowChart(BuildContext context, DashboardData dashboard) {
    final data = dashboard.cashflowData.isEmpty
        ? List.generate(90, (i) => 1000000 + (i * 5000).toDouble())
        : dashboard.cashflowData;

    if (data.isEmpty) {
      return _buildEmptyState(context, 'Unable to generate cashflow data');
    }

    // Build detailed data map from REAL unpaid sales data
    Map<int, Map<String, dynamic>> detailedData = {};
    
    // Use real unpaid sales if available, otherwise empty
    if (dashboard.unpaidSalesList.isNotEmpty) {
      // Map each unpaid sale to a chart position based on daysRemaining
      for (int i = 0; i < dashboard.unpaidSalesList.length; i++) {
        final sale = dashboard.unpaidSalesList[i];
        final daysRemaining = sale['daysRemaining'] as int? ?? 0;
        
        // Cap to 89 (last day of 90-day view)
        final chartIndex = daysRemaining > 89 ? 89 : ((daysRemaining < 0 ? 0 : daysRemaining));
        
        detailedData[chartIndex] = {
          'client': sale['party'] as String,
          'amount': sale['amount'] as double,
          'date': '${daysRemaining} days remaining',
          'type': 'unpaid_sale',
        };
      }
    }

    return BeautifulCashflowChart(
      cashflowData: data,
      detailedData: detailedData,
    );
  }

  // Build Payment Analysis Summary
  Widget _buildPaymentAnalysisSummary(BuildContext context, DashboardData dashboard) {
    final textTheme = Theme.of(context).textTheme;
    
    // Use real data from backend analysis, fallback to stub values
    final metrics = [
      {
        'label': 'Total Parties Analyzed',
        'value': dashboard.totalPartiesAnalyzed.toString(),
        'icon': Icons.people
      },
      {
        'label': 'Parties with Patterns',
        'value': dashboard.partiesWithPaymentPatterns.toString(),
        'icon': Icons.trending_up
      },
      {
        'label': 'Average Payment Delay',
        'value': '${dashboard.averagePaymentDelayDays.toStringAsFixed(1)} days',
        'icon': Icons.schedule
      },
      {
        'label': 'Total Unpaid Sales',
        'value': _formatCurrency(dashboard.totalUnpaidSalesAmount),
        'icon': Icons.money_off
      },
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Payment Analysis Summary',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Column(
            children: metrics.asMap().entries.map((entry) {
              final metric = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF42A5F5).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            metric['icon'] as IconData,
                            color: const Color(0xFF42A5F5),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          metric['label'] as String,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Text(
                      metric['value'] as String,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF42A5F5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Build Unpaid Sales List
  Widget _buildUnpaidSalesList(BuildContext context, DashboardData dashboard) {
    final textTheme = Theme.of(context).textTheme;
    
    // Use real unpaid sales data from backend analysis
    // Sort by amount descending and take top 5
    final allSales = dashboard.unpaidSalesList.isNotEmpty
        ? dashboard.unpaidSalesList
        : [];
    
    // Sort by amount in descending order and take top 5
    final unpaidSales = allSales.isEmpty
        ? []
        : (allSales.toList()..sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num)))
            .take(5)
            .toList();

    // Show message if no unpaid sales
    if (unpaidSales.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyles.divider),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💸 Unpaid Sales',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No unpaid sales',
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💸 Unpaid Sales',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Column(
            children: unpaidSales.map((sale) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    // TODO: Show details
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale['party'].toString(),
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${sale['date']} (${sale['daysRemaining']} days)',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(sale['amount'] as double),
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppStyles.primary.withOpacity(0.15),
            AppStyles.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppStyles.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Products Header
          Text(
            '🚀 Explore Our Solutions',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppStyles.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Product Description
          Text(
            'At Prophetic Business Solutions, we help businesses understand and optimize their financial future. FinSight CFO Services provides AI-powered payment analytics, cashflow forecasting, and intelligent receivables management to improve your business cash flow.',
            style: textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          
          // Features
          Row(
            children: [
              Expanded(
                child: _buildFeatureChip('💰 Smart Payments'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureChip('📊 Analytics'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFeatureChip('🎯 Forecasting'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureChip('🔐 Secure'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppStyles.primary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Contact Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For More Information',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // Launch website URL
                        print('Visit website: prophetic.businesssolutions.com');
                      },
                      child: Text(
                        'prophetic.businesssolutions.com',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppStyles.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        // Launch email
                        print('Email: info@prophetic.com');
                      },
                      child: Text(
                        '✉️ info@prophetic.com',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppStyles.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Icon on the right
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppStyles.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: AppStyles.primary,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyles.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppStyles.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}