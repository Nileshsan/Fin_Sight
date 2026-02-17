import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../config/theme.dart';

class DiscountsScreen extends ConsumerStatefulWidget {
  const DiscountsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends ConsumerState<DiscountsScreen> {
  String _selectedCategory = 'All';

  String _formatCurrency(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'A':
        return AppStyles.success;
      case 'B':
        return AppStyles.primary;
      case 'C':
        return AppStyles.warning;
      case 'D':
        return Colors.red;
      default:
        return AppStyles.primary;
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'A':
        return '⚡';
      case 'B':
        return '✓';
      case 'C':
        return '⏱';
      case 'D':
        return '⚠';
      default:
        return '•';
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'A':
        return 'Fast Payer';
      case 'B':
        return 'Normal Payer';
      case 'C':
        return 'Slow Payer';
      case 'D':
        return 'Outlier/Risk';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Incentives'),
        elevation: 0,
      ),
      body: dashboardAsync.when(
        data: (dashboard) {
          // Use parties data from backend - it has all financial info
          final allDiscounts = <Map<String, dynamic>>[];
          double totalDiscountPool = 0;

          // Initialize categoryMap for stats calculation
          final categoryMap = {
            'A': dashboard.categories?.categories['A'] ?? [],
            'B': dashboard.categories?.categories['B'] ?? [],
            'C': dashboard.categories?.categories['C'] ?? [],
            'D': dashboard.categories?.categories['D'] ?? [],
          };

          // If parties data is available, use it (preferred)
          if (dashboard.parties.isNotEmpty) {
            for (final party in dashboard.parties) {
              allDiscounts.add({
                'party': party.partyName,
                'party_name': party.partyName,
                'category': party.category,
                'closing_balance': party.closingBalance, // ✅ Real value
                'sales_amount': party.closingBalance, // Use closing balance as amount due
                'discount_amount': party.discountAmount, // ✅ Real calculated discount
                'discount_percent': party.discountPct, // ✅ Real percentage
                'discount_pct': party.discountPct,
                'days_remaining': party.daysRemaining, // ✅ Real days
                'expected_date': party.predictedPaymentDate, // ✅ Real date
                'unpaid_sales_count': party.unpaidSalesCount,
                'amount_if_paid_today': party.closingBalance - party.discountAmount,
              });
              totalDiscountPool += party.discountAmount;
            }
          } else {
            // Fallback to categories data if parties not available
            categoryMap.forEach((catLabel, clients) {
              for (final client in clients) {
                final daysRemaining = (client.avgPaymentDays ?? 0).toInt();
                final discountAmount = (client.discount ?? 0) * 0.01; // Convert percentage to amount
                allDiscounts.add({
                  'party': client.party,
                  'category': catLabel,
                  'closing_balance': 0.0,
                  'sales_amount': 0.0,
                  'days_remaining': daysRemaining,
                  'expected_date': null,
                  'discount_percent': client.discount,
                  'discount_pct': client.discount,
                  'discount_amount': 0.0,
                  'unpaid_sales_count': 0,
                });
                totalDiscountPool += discountAmount;
              }
            });
          }

          // Filter by selected category
          final filteredDiscounts = _selectedCategory == 'All'
              ? allDiscounts
              : allDiscounts.where((d) => d['category'] == _selectedCategory).toList();

          // Sort by discount amount (highest first)
          filteredDiscounts.sort((a, b) => (b['discount_amount'] as double)
              .compareTo(a['discount_amount'] as double));

          // Calculate metrics by category
          final categoryStats = <String, Map<String, dynamic>>{};
          for (final entry in categoryMap.entries) {
            double catTotalDiscount = 0;
            int catCount = 0;
            for (final partyData in allDiscounts) {
              if (partyData['category'] == entry.key) {
                catCount++;
                catTotalDiscount += (partyData['discount_amount'] as double? ?? 0.0);
              }
            }
            categoryStats[entry.key] = {
              'count': catCount,
              'total': catTotalDiscount,
              'avg': catCount > 0 ? catTotalDiscount / catCount : 0,
            };
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardDataProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Revenue Increase Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppStyles.success.withOpacity(0.2), AppStyles.success.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppStyles.success.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppStyles.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up_rounded, color: Colors.green, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Possible Revenue Increase',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(totalDiscountPool),
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppStyles.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Expected additional revenue from ${allDiscounts.length} clients by offering early payment discounts',
                            style: textTheme.labelSmall?.copyWith(color: Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Stats Grid
                  Text(
                    'Revenue Impact by Category',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final catLabel = ['A', 'B', 'C', 'D'][index];
                      final stats = categoryStats[catLabel]!;
                      final color = _getCategoryColor(catLabel);
                      final icon = _getCategoryIcon(catLabel);

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 24)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    catLabel,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getCategoryName(catLabel),
                                  style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCurrency(stats['total'] as double),
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${stats['count']} clients',
                                  style: textTheme.labelSmall?.copyWith(color: AppStyles.grey, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Filter and List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount Opportunities',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${filteredDiscounts.length} clients',
                        style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'A', 'B', 'C', 'D'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              cat == 'All' ? 'All Categories' : 'Category $cat',
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = cat);
                            },
                            backgroundColor: Colors.white,
                            selectedColor: _getCategoryColor(cat).withOpacity(0.2),
                            side: BorderSide(
                              color: isSelected ? _getCategoryColor(cat) : AppStyles.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Discount List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDiscounts.length,
                    itemBuilder: (context, index) {
                      final discount = filteredDiscounts[index];
                      final category = discount['category'] as String;
                      final color = _getCategoryColor(category);
                      final icon = _getCategoryIcon(category);

                      return Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(icon, style: const TextStyle(fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        discount['party'] as String,
                                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_getCategoryName(category)} (Category $category)',
                                        style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${(discount['discount_percent'] as double).toStringAsFixed(1)}%',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Financial Info
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoColumn(
                                    label: 'Original Amount',
                                    value: _formatCurrency(discount['sales_amount'] as double),
                                    textTheme: textTheme,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoColumn(
                                    label: 'Discount Amount',
                                    value: _formatCurrency(discount['discount_amount'] as double),
                                    valueColor: AppStyles.success,
                                    textTheme: textTheme,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoColumn(
                                    label: 'Days Remaining',
                                    value: '${discount['days_remaining']} days',
                                    textTheme: textTheme,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Additional Details
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppStyles.divider.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Expected Payment: ${discount['expected_date']}',
                                    style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                                  ),
                                  Text(
                                    'Closing Balance: ${_formatCurrency(discount['closing_balance'] as double)}',
                                    style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _approveDiscount(context, discount, ref),
                                icon: const Icon(Icons.check_circle_rounded, size: 18),
                                label: const Text('Send Discount Offer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading discounts: $error'),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
    Color? valueColor,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _approveDiscount(
    BuildContext context,
    Map<String, dynamic> discount,
    WidgetRef ref,
  ) {
    final category = discount['category'] as String? ?? 'D';
    final color = _getCategoryColor(category);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Send Discount Offer?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send discount offer to ${discount['party']}?'),
            const SizedBox(height: 16),
            _buildDetailRow('Amount Due', _formatCurrency(discount['closing_balance'] as double)),
            _buildDetailRow('Discount Offer', _formatCurrency(discount['discount_amount'] as double)),
            _buildDetailRow('Amount if Paid Today', _formatCurrency(discount['amount_if_paid_today'] as double)),
            _buildDetailRow('Days Remaining', '${discount['days_remaining']} days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _sendDiscountEmail(context, discount, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendDiscountEmail(
    BuildContext context,
    Map<String, dynamic> discount,
    WidgetRef ref,
  ) async {
    try {
      final transactionService = ref.read(transactionServiceProvider);

      // Get email from party data
      final dashboardAsync = ref.watch(dashboardDataProvider);
      final dashboard = dashboardAsync.whenData((data) => data).value;

      if (dashboard == null) throw Exception('Dashboard data not available');

      // Find party data
      final partyDataList = dashboard.parties.where(
        (p) => p.partyName == discount['party'],
      ).toList();

      if (partyDataList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Party data not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final partyData = partyDataList.first;

      if ((partyData.clientEmail ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No email available for ${discount['party']}. Please add email first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Send discount via backend
      final response = await transactionService.sendEmailToParty(
        partyName: discount['party'] as String,
        email: partyData.clientEmail!,
        subject: 'Early Payment Discount Offer - Save ₹${(discount['discount_amount'] as num).toStringAsFixed(0)}',
        body: _getDiscountEmailTemplate(discount['category'] as String, discount),
        discountDetails: {
          'closing_balance': discount['closing_balance'],
          'discount_amount': discount['discount_amount'],
          'discount_pct': discount['discount_pct'],
          'amount_if_paid_today': discount['amount_if_paid_today'],
          'days_remaining': discount['days_remaining'],
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Discount offer sent successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.refresh(dashboardDataProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending discount: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getDiscountEmailTemplate(String category, Map<String, dynamic> discount) {
    final amount = _formatCurrency(discount['closing_balance'] as double);
    final discountAmount = _formatCurrency(discount['discount_amount'] as double);
    final discountPct = (discount['discount_pct'] as double).toStringAsFixed(2);
    final daysRemaining = discount['days_remaining'];

    switch (category) {
      case 'A':
        return '''Dear ${discount['party']},

Thank you for being a valued customer and maintaining excellent payment records.

We have a special early payment offer for you:

Current Outstanding Balance: $amount
Early Payment Discount Available: $discountAmount ($discountPct%)
Amount if Paid Today: ${_formatCurrency(discount['amount_if_paid_today'] as double)}

If you pay within $daysRemaining days, you can avail this discount.

Best regards,
Finance Team''';
      case 'B':
        return '''Dear ${discount['party']},

We appreciate your continued business relationship.

We have a special early payment incentive for you:

Current Outstanding Balance: $amount
Discount Offer: $discountAmount ($discountPct%)
Discounted Amount: ${_formatCurrency(discount['amount_if_paid_today'] as double)}

With your typical payment pattern, paying within $daysRemaining days can help you save this amount.

Best regards,
Finance Team''';
      case 'C':
        return '''Dear ${discount['party']},

We would like to offer you an attractive payment incentive.

Outstanding Invoice: $amount
Early Payment Discount: $discountAmount ($discountPct%)
Net Amount if Paid Today: ${_formatCurrency(discount['amount_if_paid_today'] as double)}

Pay within $daysRemaining days to benefit from this offer.

Contact us for any queries.

Best regards,
Finance Team''';
      default:
        return '''Dear ${discount['party']},

We have an urgent payment matter requiring your attention.

Outstanding Amount: $amount
Special Discount if Paid Immediately: $discountAmount ($discountPct%)

Please settle at your earliest convenience to benefit from this reduced amount.

Contact us immediately.

Best regards,
Finance Team''';
    }
  }
}

class DiscountRuleBuilder extends ConsumerStatefulWidget {
  final String? partyId;

  const DiscountRuleBuilder({
    this.partyId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DiscountRuleBuilder> createState() => _DiscountRuleBuilderState();
}

class _DiscountRuleBuilderState extends ConsumerState<DiscountRuleBuilder> {
  late TextEditingController _daysController;
  late TextEditingController _discountController;
  late TextEditingController _minAmountController;
  bool _isLoading = false;

  // Current client data
  Map<String, dynamic>? _clientData;
  double _projectedCashflow = 0;
  double _projectedEarnings = 0;

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: '15');
    _discountController = TextEditingController(text: '2');
    _minAmountController = TextEditingController(text: '0');
    _loadClientData();
  }

  void _loadClientData() {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    dashboardAsync.whenData((dashboard) {
      final categoryMap = {
        'A': dashboard.categories?.categories['A'] ?? [],
        'B': dashboard.categories?.categories['B'] ?? [],
        'C': dashboard.categories?.categories['C'] ?? [],
        'D': dashboard.categories?.categories['D'] ?? [],
      };

      for (final clients in categoryMap.values) {
        for (final client in clients) {
          if (client.party == widget.partyId) {
            final daysRemaining = (client.avgPaymentDays ?? 0).toInt();
            setState(() {
              _clientData = {
                'party': client.party,
                'category': client.category,
                'closing_balance': 0.0,
                'sales_amount': 0.0,
                'expected_date': null,
                'days_remaining': daysRemaining,
              };
            });
            break;
          }
        }
      }
    });
  }

  void _calculateProjections() {
    final days = int.tryParse(_daysController.text) ?? 15;
    final discountPercent = double.tryParse(_discountController.text) ?? 2;

    if (_clientData != null) {
      final salesAmount = _clientData!['sales_amount'] as double;
      final discountAmount = salesAmount * (discountPercent / 100);

      // Simulate getting paid earlier
      final daysEarly = (_clientData!['days_remaining'] as int) - days;
      
      setState(() {
        _projectedCashflow = discountAmount;
        _projectedEarnings = daysEarly > 0 ? (discountAmount * 0.05) : 0; // 5% of discount as earnings
      });
    }
  }

  Future<void> _submitDiscount() async {
    if (_clientData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client data not loaded. Please wait.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final days = int.tryParse(_daysController.text) ?? 15;
      final discountPercent = double.tryParse(_discountController.text) ?? 2;

      // TODO: Send to backend API
      // POST /api/transactions/live/discounts/offer/
      // {
      //   "party_name": widget.partyId,
      //   "discount_percent": discountPercent,
      //   "if_paid_within_days": days,
      //   "status": "pending_approval"
      // }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Discount offer created for ${widget.partyId}!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh dashboard
      ref.refresh(dashboardDataProvider);

      Future.delayed(const Duration(milliseconds: 500)).then((_) {
        if (mounted) context.go('/discounts');
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _daysController.dispose();
    _discountController.dispose();
    _minAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Discount Offer'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Discount Incentive Proposal',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure discount offer to accelerate cash collection.',
              style: textTheme.bodyMedium?.copyWith(color: AppStyles.grey),
            ),
            const SizedBox(height: 24),

            // Client Info Card
            if (_clientData != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppStyles.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppStyles.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppStyles.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.account_circle, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _clientData!['party'] as String,
                                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Category ${_clientData!['category']} • ₹${(_clientData!['closing_balance'] as double).toStringAsFixed(0)} outstanding',
                                style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
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
                        _buildStatColumn(
                          label: 'Sales Amount',
                          value: '₹${((_clientData!['sales_amount'] as double) / 100000).toStringAsFixed(1)}L',
                          textTheme: textTheme,
                        ),
                        _buildStatColumn(
                          label: 'Expected Payment',
                          value: _clientData!['expected_date'] as String,
                          textTheme: textTheme,
                        ),
                        _buildStatColumn(
                          label: 'Days Remaining',
                          value: '${_clientData!['days_remaining']} days',
                          textTheme: textTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppStyles.divider.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Party: ${widget.partyId ?? 'Unknown'}',
                  style: textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 24),

            // Config Section
            Text(
              'Discount Configuration',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Days Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppStyles.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If payment within (days)',
                    style: textTheme.bodySmall?.copyWith(color: AppStyles.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateProjections(),
                    decoration: InputDecoration(
                      hintText: '15',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      suffixText: 'days',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Discount Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppStyles.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Give discount of (percentage)',
                    style: textTheme.bodySmall?.copyWith(color: AppStyles.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateProjections(),
                    decoration: InputDecoration(
                      hintText: '2',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      suffixText: '%',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Min Amount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppStyles.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minimum transaction amount (optional)',
                    style: textTheme.bodySmall?.copyWith(color: AppStyles.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _minAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      prefixText: '₹ ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Projections
            Text(
              'Impact Projections',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Projected Cashflow',
                          style: textTheme.labelSmall?.copyWith(color: Colors.green[700]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${(_projectedCashflow / 100000).toStringAsFixed(1)}L',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'faster collection',
                          style: textTheme.labelSmall?.copyWith(color: Colors.green[600], fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppStyles.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppStyles.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Projected Earnings',
                          style: textTheme.labelSmall?.copyWith(color: AppStyles.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${(_projectedEarnings / 1000).toStringAsFixed(1)}K',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppStyles.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'extra revenue',
                          style: textTheme.labelSmall?.copyWith(color: AppStyles.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Offer ${_discountController.text}% discount to ${widget.partyId ?? 'party'} if they pay within ${_daysController.text} days. This can accelerate cash collection and improve working capital.',
                    style: textTheme.bodySmall?.copyWith(color: AppStyles.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitDiscount,
                icon: _isLoading ? null : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(_isLoading ? 'Creating...' : 'Create & Send Offer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: AppStyles.grey, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
