import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../providers/dashboard_provider.dart';

class CashflowScreen extends ConsumerStatefulWidget {
  const CashflowScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CashflowScreen> createState() => _CashflowScreenState();
}

class _CashflowScreenState extends ConsumerState<CashflowScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashflow Forecast (90 Days)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(dashboardDataProvider),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error loading cashflow', style: textTheme.titleMedium),
              Text(err.toString(), style: textTheme.bodySmall),
            ],
          ),
        ),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async => ref.refresh(dashboardDataProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Cashflow Graph
                Text(
                  'Predicted Balance Trend',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (dashboard.cashflowData.isEmpty)
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppStyles.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppStyles.divider),
                    ),
                    child: Center(
                      child: Text(
                        'No cashflow data available',
                        style: textTheme.bodyMedium?.copyWith(color: AppStyles.grey),
                      ),
                    ),
                  )
                else
                  _buildCashflowGraph(context, dashboard, textTheme),
                const SizedBox(height: 24),

                // Client Categories (A/B/C/D) with counts
                Text(
                  'Client Categories Distribution',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildCategoryStats(context, dashboard, textTheme),
                const SizedBox(height: 24),

                // Key Metrics
                Text(
                  'Financial Metrics',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildMetricsCards(context, dashboard, textTheme),
                const SizedBox(height: 24),

                // Collection Forecast
                Text(
                  '30/60/90 Day Collection Forecast',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildForecastTable(context, dashboard, textTheme),
                const SizedBox(height: 16),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Generated: ${dashboard.generatedAt ?? "Today"}',
                        style: textTheme.bodySmall?.copyWith(color: AppStyles.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time analysis • Based on ${dashboard.cashflowData.length} days',
                        style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                      ),
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

  Widget _buildCashflowGraph(
    BuildContext context,
    DashboardData dashboard,
    TextTheme textTheme,
  ) {
    final data = dashboard.cashflowData;

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final padding = range * 0.1;

    final spots = List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index]);
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (range / 4).abs() > 0 ? (range / 4).abs() : 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppStyles.divider,
                      strokeWidth: 0.5,
                      dashArray: [5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (data.length / 6).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index % 15 == 0 && index < data.length) {
                          return Text(
                            'Day ${index + 1}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppStyles.grey,
                              fontSize: 10,
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
                      interval: (range / 4).abs() > 0 ? (range / 4).abs() : 1000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCurrencyShort(value),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppStyles.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: AppStyles.divider, width: 0.5),
                    bottom: BorderSide(color: AppStyles.divider, width: 0.5),
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
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppStyles.primary.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot spot) {
                        return LineTooltipItem(
                          'Day ${spot.x.toInt() + 1}\n${_formatCurrency(spot.y)}',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppStyles.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Predicted Balance (₹ • Next ${data.length} days)',
                style: textTheme.bodySmall?.copyWith(
                  color: AppStyles.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(
    BuildContext context,
    DashboardData dashboard,
    TextTheme textTheme,
  ) {
    final categories = dashboard.categories;
    if (categories == null) {
      return Text(
        'No category data available',
        style: textTheme.bodyMedium?.copyWith(color: AppStyles.grey),
      );
    }

    final catA = categories.categories['A'] ?? [];
    final catB = categories.categories['B'] ?? [];
    final catC = categories.categories['C'] ?? [];
    final catD = categories.categories['D'] ?? [];
    final total = catA.length + catB.length + catC.length + catD.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildCategoryCard(
          context: context,
          category: 'A - Fast Payers',
          count: catA.length,
          total: total,
          color: AppStyles.success,
          description: 'Early & On-time',
          icon: Icons.trending_up,
        ),
        _buildCategoryCard(
          context: context,
          category: 'B - Normal Payers',
          count: catB.length,
          total: total,
          color: AppStyles.primary,
          description: 'Acceptable',
          icon: Icons.check_circle,
        ),
        _buildCategoryCard(
          context: context,
          category: 'C - Slow Payers',
          count: catC.length,
          total: total,
          color: AppStyles.warning,
          description: 'Late payments',
          icon: Icons.schedule,
        ),
        _buildCategoryCard(
          context: context,
          category: 'D - Outliers',
          count: catD.length,
          total: total,
          color: Colors.red,
          description: 'High Risk',
          icon: Icons.warning_rounded,
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String category,
    required int count,
    required int total,
    required Color color,
    required String description,
    required IconData icon,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final percentage = total > 0 ? ((count / total) * 100).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '$percentage%',
                style: textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: AppStyles.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(
    BuildContext context,
    DashboardData dashboard,
    TextTheme textTheme,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildMetricCard(
          label: 'Total Receivables',
          value: _formatCurrency(dashboard.totalReceivables),
          icon: Icons.account_balance_wallet,
          color: AppStyles.primary,
        ),
        _buildMetricCard(
          label: 'Expected Cash (7d)',
          value: _formatCurrency(dashboard.expectedCash7d),
          icon: Icons.calendar_today,
          color: AppStyles.success,
        ),
        _buildMetricCard(
          label: 'On-Time Rate',
          value: '${dashboard.onTimeRate.toStringAsFixed(1)}%',
          icon: Icons.check_circle,
          color: Colors.amber,
        ),
        _buildMetricCard(
          label: 'High-Risk Amount',
          value: _formatCurrency(dashboard.highRiskAmount),
          icon: Icons.warning,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppStyles.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTable(
    BuildContext context,
    DashboardData dashboard,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.divider),
      ),
      child: Column(
        children: [
          _buildForecastRow(
            label: 'Period',
            conservative: 'Conservative',
            likely: 'Likely',
            optimistic: 'Optimistic',
            isHeader: true,
            textTheme: textTheme,
          ),
          const Divider(height: 12),
          _buildForecastRow(
            label: '30 Days',
            conservative: _formatCurrency(dashboard.expectedCash7d * 4 * 0.7),
            likely: _formatCurrency(dashboard.expectedCash7d * 4 * 0.85),
            optimistic: _formatCurrency(dashboard.expectedCash7d * 4),
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          _buildForecastRow(
            label: '60 Days',
            conservative: _formatCurrency(dashboard.expectedCash7d * 8 * 0.65),
            likely: _formatCurrency(dashboard.expectedCash7d * 8 * 0.80),
            optimistic: _formatCurrency(dashboard.expectedCash7d * 8),
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          _buildForecastRow(
            label: '90 Days',
            conservative: _formatCurrency(dashboard.totalReceivables * 0.75),
            likely: _formatCurrency(dashboard.totalReceivables * 0.90),
            optimistic: _formatCurrency(dashboard.totalReceivables),
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow({
    required String label,
    required String conservative,
    required String likely,
    required String optimistic,
    required TextTheme textTheme,
    bool isHeader = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isHeader
                ? textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)
                : textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Text(
            conservative,
            textAlign: TextAlign.center,
            style: isHeader
                ? textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)
                : textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Text(
            likely,
            textAlign: TextAlign.center,
            style: isHeader
                ? textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)
                : textTheme.bodySmall?.copyWith(
              color: AppStyles.primary,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Text(
            optimistic,
            textAlign: TextAlign.center,
            style: isHeader
                ? textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)
                : textTheme.bodySmall?.copyWith(
              color: AppStyles.success,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatCurrencyShort(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(0)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(0)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }
}
