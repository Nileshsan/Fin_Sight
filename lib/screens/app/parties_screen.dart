import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/transaction_service.dart';

class PartiesScreen extends ConsumerStatefulWidget {
  const PartiesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends ConsumerState<PartiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties / Clients'),
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
          child: Text('Error: $err'),
        ),
        data: (dashboard) {
          // Use parties data from backend - it has all financial info
          final allClients = <Map<String, dynamic>>[];

          // Build client list from parties array (preferred - has all data)
          if (dashboard.parties.isNotEmpty) {
            for (final party in dashboard.parties) {
              String categoryName = '';
              String categoryIcon = '';
              Color categoryColor = AppStyles.primary;

              switch (party.category) {
                case 'A':
                  categoryName = 'Fast Payer';
                  categoryIcon = '⚡';
                  categoryColor = AppStyles.success;
                  break;
                case 'B':
                  categoryName = 'Normal Payer';
                  categoryIcon = '✓';
                  categoryColor = AppStyles.primary;
                  break;
                case 'C':
                  categoryName = 'Slow Payer';
                  categoryIcon = '⏱';
                  categoryColor = AppStyles.warning;
                  break;
                case 'D':
                  categoryName = 'Outlier/Risk';
                  categoryIcon = '⚠';
                  categoryColor = Colors.red;
                  break;
              }

              allClients.add({
                'name': party.partyName,
                'party_name': party.partyName, // Add party_name for reference
                'closing_balance': party.closingBalance, // ✅ Real value from backend
                'sales_amount': party.closingBalance, // Use closing balance as amount due
                'expected_date': party.predictedPaymentDate, // ✅ Real date
                'days_remaining': party.daysRemaining, // ✅ Real days
                'category': party.category,
                'category_name': categoryName,
                'category_icon': categoryIcon,
                'category_color': categoryColor,
                'discount': party.discountPct, // Discount percentage
                'discount_amount': party.discountAmount, // ✅ Real discount amount
                'client_email': party.clientEmail, // For email button
                'has_email': party.hasEmail, // For email button
              });
            }
          } else {
            // Fallback to categories data if parties not available
            final categories = dashboard.categories;
            if (categories == null) {
              return Center(
                child: Text('No client data available', style: textTheme.bodyMedium),
              );
            }

            final categoryMap = categories.categories;
            for (final entry in categoryMap.entries) {
              final catLabel = entry.key;
              final clients = entry.value;

              String categoryName = '';
              String categoryIcon = '';
              Color categoryColor = AppStyles.primary;

              switch (catLabel) {
                case 'A':
                  categoryName = 'Fast Payer';
                  categoryIcon = '⚡';
                  categoryColor = AppStyles.success;
                  break;
                case 'B':
                  categoryName = 'Normal Payer';
                  categoryIcon = '✓';
                  categoryColor = AppStyles.primary;
                  break;
                case 'C':
                  categoryName = 'Slow Payer';
                  categoryIcon = '⏱';
                  categoryColor = AppStyles.warning;
                  break;
                case 'D':
                  categoryName = 'Outlier/Risk';
                  categoryIcon = '⚠';
                  categoryColor = Colors.red;
                  break;
              }

              for (final client in clients) {
                final daysRemaining = (client.avgPaymentDays ?? 0).toInt();
                
                allClients.add({
                  'name': client.party,
                  'party_name': client.party,
                  'closing_balance': 0.0,
                  'sales_amount': 0.0,
                  'expected_date': null,
                  'days_remaining': daysRemaining,
                  'category': catLabel,
                  'category_name': categoryName,
                  'category_icon': categoryIcon,
                  'category_color': categoryColor,
                  'discount': client.discount,
                  'discount_amount': 0.0,
                  'client_email': null,
                  'has_email': false,
                });
              }
            }
          }

          // Filter by search
          var filteredClients = allClients;
          final searchText = _searchController.text.toLowerCase();
          if (searchText.isNotEmpty) {
            filteredClients = allClients
                .where((c) => c['name'].toString().toLowerCase().contains(searchText))
                .toList();
          }

          // Filter by category
          if (_selectedCategory != 'all') {
            filteredClients =
                filteredClients.where((c) => c['category'] == _selectedCategory).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search clients...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Category Filter
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All Clients', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('⚡ Fast (A)', 'A'),
                      const SizedBox(width: 8),
                      _buildFilterChip('✓ Normal (B)', 'B'),
                      const SizedBox(width: 8),
                      _buildFilterChip('⏱ Slow (C)', 'C'),
                      const SizedBox(width: 8),
                      _buildFilterChip('⚠ Risk (D)', 'D'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppStyles.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_rounded, color: AppStyles.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Showing ${filteredClients.length} of ${allClients.length} clients',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Client List
                if (filteredClients.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No clients found', style: textTheme.bodyMedium),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return _buildClientCard(context, client, textTheme);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = value);
      },
      backgroundColor: Colors.white,
      selectedColor: AppStyles.primary.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? AppStyles.primary : AppStyles.divider,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    Map<String, dynamic> client,
    TextTheme textTheme,
  ) {
    final color = client['category_color'] as Color;

    return GestureDetector(
      onTap: () => _showClientDetailsModal(context, client, textTheme),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppStyles.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  client['category_icon'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Client Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client['name'] as String,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${client['category_name']} (${client['category']})',
                          style: textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if ((client['days_remaining'] as int) > 0)
                        Text(
                          'Pay in ${client['days_remaining']}d',
                          style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(client['closing_balance'] as double),
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClientDetailsModal(
    BuildContext context,
    Map<String, dynamic> client,
    TextTheme textTheme,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (client['category_color'] as Color),
                      (client['category_color'] as Color).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              client['category_icon'] as String,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client['name'] as String,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Category ${client['category']}: ${client['category_name']}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Financial Details
                    _buildDetailSection(
                      title: 'Financial Details',
                      children: [
                        _buildDetailRow(
                          label: 'Closing Balance',
                          value: _formatCurrency(client['closing_balance'] as double),
                          icon: Icons.account_balance_wallet,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          label: 'Sales/Receipts Due',
                          value: _formatCurrency(client['sales_amount'] as double),
                          icon: Icons.receipt_long,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          label: 'Discount Available',
                          value: '${(client['discount'] as double).toStringAsFixed(2)}% (₹${(client['discount_amount'] as double).toStringAsFixed(0)})',
                          icon: Icons.local_offer,
                          valueColor: AppStyles.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Payment Info
                    _buildDetailSection(
                      title: 'Payment Information',
                      children: [
                        _buildDetailRow(
                          label: 'Expected Payment Date',
                          value: (client['expected_date'] as String? ?? 'Not available'),
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          label: 'Days Remaining',
                          value: '${client['days_remaining']} days',
                          icon: Icons.schedule,
                          valueColor: _getDaysColor(client['days_remaining'] as int),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Payment Habit
                    _buildDetailSection(
                      title: 'Payment Habit',
                      children: [
                        _buildHabitDisplay(client['category'] as String),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              // Navigate to discounts page - the whole page will show all discounts
                              // User can search for this party or filter by category
                              context.go('/discounts');
                            },
                            icon: const Icon(Icons.local_offer_rounded, size: 18),
                            label: const Text('Discount'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyles.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              // Navigate to email center page
                              context.go('/emails');
                            },
                            icon: const Icon(Icons.mail_rounded, size: 18),
                            label: const Text('Email'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppStyles.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppStyles.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodySmall,
          ),
        ),
        Text(
          value,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildHabitDisplay(String category) {
    String habitText = '';
    String habitDescription = '';
    Color habitColor = AppStyles.primary;

    switch (category) {
      case 'A':
        habitText = '⚡ Fast Payer';
        habitDescription = 'Consistently pays early or on-time. Very reliable.';
        habitColor = AppStyles.success;
        break;
      case 'B':
        habitText = '✓ Normal Payer';
        habitDescription = 'Pays within acceptable timeframe. Fairly reliable.';
        habitColor = AppStyles.primary;
        break;
      case 'C':
        habitText = '⏱ Slow Payer';
        habitDescription = 'Pays late but eventually settles. Needs monitoring.';
        habitColor = AppStyles.warning;
        break;
      case 'D':
        habitText = '⚠ Outlier/Risk';
        habitDescription = 'Irregular payment pattern. High risk & requires close monitoring.';
        habitColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: habitColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: habitColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            habitText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: habitColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            habitDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: habitColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDaysColor(int days) {
    if (days <= 0) return Colors.red;
    if (days <= 7) return AppStyles.warning;
    if (days <= 30) return AppStyles.primary;
    return AppStyles.success;
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }
}
