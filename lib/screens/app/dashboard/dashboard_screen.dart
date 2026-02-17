import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';

import '../../constants/index.dart';
import '../../utils/index.dart';

/// Dashboard Screen
/// Displays financial summary and key metrics
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  String _selectedPeriod = 'month'; // 'week', 'month', 'year'
  bool _refreshing = false;
  bool _showBankModal = false;
  final TextEditingController _bankController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController.forward();
    _loadDashboard();
    _checkBankModal();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    // Load dashboard data
    // This will be connected to provider later
  }

  Future<void> _checkBankModal() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('bank_modal_shown') ?? false;
    if (!seen) {
      setState(() => _showBankModal = true);
    }
  }

  Future<void> _dismissBankModal({bool save = false}) async {
    if (save) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bank_modal_shown', true);
      // store bank balance for now as string - integration later
      await prefs.setString('bank_balance', _bankController.text.trim());
    }
    setState(() => _showBankModal = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadDashboard();
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank balance modal is displayed above blurred content
                if (_showBankModal) _buildBlurredBankModal(context),
                // Period Selector
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['week', 'month', 'year'].map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            period.toUpperCase(),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.gray700,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedPeriod = period);
                          },
                          backgroundColor: AppColors.gray100,
                          selectedColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Stat Cards
                _buildStatCard(
                  title: 'Total Revenue',
                  value: '₹11,272,872',
                  change: '+12.5%',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  isPositive: true,
                ),
                const SizedBox(height: 12),
                // 90-day scrollable cashflow chart
                const Text('Projected Cashflow (90 days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 90 * 18.0, // 90 points, ~18px each
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: LineChart(_buildLineChartData()),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                  title: 'Cash Flow',
                  value: '₹2,463,872',
                  change: '+8.2%',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.info,
                  isPositive: true,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  title: 'Expenses',
                  value: '₹1,272,872',
                  change: '-3.1%',
                  icon: Icons.trending_down,
                  color: AppColors.warning,
                  isPositive: false,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  title: 'Profit Margin',
                  value: '38.5%',
                  change: '+2.1%',
                  icon: Icons.show_chart,
                  color: AppColors.secondary,
                  isPositive: true,
                ),
                const SizedBox(height: 32),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                // Top 5 clients section (placeholder until API wired)
                const Text('Top 5 incoming clients', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTopClientsPlaceholder(),
                const SizedBox(height: 16),

                // Alerts
                const Text('Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildAlertsPlaceholder(),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(
                      label: 'Add Transaction',
                      icon: Icons.add_circle_outline,
                      onTap: () {
                        // Navigate to add transaction
                      },
                    ),
                    _buildQuickActionButton(
                      label: 'View Cashflow',
                      icon: Icons.show_chart,
                      onTap: () {
                        // Navigate to cashflow
                      },
                    ),
                    _buildQuickActionButton(
                      label: 'Clients',
                      icon: Icons.people_outline,
                      onTap: () {
                        // Navigate to clients
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    // Generate 90-day sample data. Replace with real API data later.
    final spots = List.generate(90, (i) => FlSpot(i.toDouble(), (1000000 + (i - 45) * 8000 + (i % 7) * 40000).toDouble()));

    return LineChartData(
      gridData: FlGridData(show: true, horizontalInterval: 200000),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 14, getTitlesWidget: (value, meta) {
          final idx = value.toInt();
          if (idx % 14 == 0) {
            final label = DateTime.now().add(Duration(days: idx)).toString().substring(5,10);
            return Text(label, style: const TextStyle(fontSize: 10));
          }
          return const SizedBox.shrink();
        })),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.12)),
        ),
      ],
    );
  }

  Widget _buildBlurredBankModal(BuildContext context) {
    return Stack(
      children: [
        // blurred backdrop
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(
            color: Colors.black.withOpacity(0.25),
            height: MediaQuery.of(context).size.height,
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Quick Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Enter your current bank balance to personalise the dashboard forecasts.'),
                const SizedBox(height: 12),
                TextField(controller: _bankController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bank balance')),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => _dismissBankModal(save: false), child: const Text('Skip')),
                  ElevatedButton(onPressed: () => _dismissBankModal(save: true), child: const Text('Save')),
                ])
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopClientsPlaceholder() {
    final mock = List.generate(5, (i) => {'name': 'Client ${i+1}', 'amount': '₹${(5 - i) * 250000}'});
    return Column(children: mock.map((c) => ListTile(title: Text(c['name']!), trailing: Text(c['amount']!))).toList());
  }

  Widget _buildAlertsPlaceholder() {
    final alerts = [
      {'level': 'warning', 'text': 'No incoming cash in next 10 days'},
      {'level': 'info', 'text': '3 Category D clients with late payments'},
    ];
    return Column(children: alerts.map((a) => ListTile(leading: Icon(a['level'] == 'warning' ? Icons.warning_amber_rounded : Icons.info_outline), title: Text(a['text']!))).toList());
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? change,
    required IconData icon,
    required Color color,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          if (change != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPositive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}
