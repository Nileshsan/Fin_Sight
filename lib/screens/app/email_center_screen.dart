import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../config/theme.dart';

class EmailCenterScreen extends ConsumerStatefulWidget {
  const EmailCenterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailCenterScreen> createState() => _EmailCenterScreenState();
}

class _EmailCenterScreenState extends ConsumerState<EmailCenterScreen> {
  String _selectedTab = 'ready'; // 'ready', 'sent', 'failed'
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

  String _getEmailTemplate(String category) {
    switch (category) {
      case 'A':
        return 'Thank you for your prompt payment! We appreciate your business and reliability.';
      case 'B':
        return 'This is a friendly reminder about your outstanding payment. Please settle at your earliest convenience.';
      case 'C':
        return 'We noticed your payment is overdue. We offer a 2% discount if paid within 7 days.';
      case 'D':
        return 'Urgent: Your account is significantly overdue. Please contact us immediately to arrange payment.';
      default:
        return 'Payment reminder for your outstanding invoice.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Center'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppStyles.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📧 ${_selectedTab == 'ready' ? 'Ready' : _selectedTab == 'sent' ? 'Sent' : 'Failed'}',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppStyles.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (dashboard) {
          // Use parties data from backend - it has all financial info
          final allEmails = <Map<String, dynamic>>[];

          // If parties data is available, use it (preferred)
          if (dashboard.parties.isNotEmpty) {
            for (final party in dashboard.parties) {
              allEmails.add({
                'party': party.partyName,
                'party_name': party.partyName,
                'category': party.category,
                'email': party.clientEmail ?? '',
                'closing_balance': party.closingBalance, // ✅ Correct balance
                'sales_amount': party.closingBalance, // Use closing balance as sales
                'days_remaining': party.daysRemaining, // ✅ Correct days
                'expected_date': party.predictedPaymentDate, // ✅ Correct date
                'discount_amount': party.discountAmount, // ✅ Correct discount
                'discount_percent': party.discountPct,
                'has_email': party.hasEmail,
                'can_add_email': party.canAddEmail,
                'status': party.hasEmail ? 'ready' : 'no_email',
                'sent_date': null,
                'opened': false,
              });
            }
          } else {
            // Fallback to categories data if parties not available
            final categoryMap = {
              'A': dashboard.categories?.categories['A'] ?? [],
              'B': dashboard.categories?.categories['B'] ?? [],
              'C': dashboard.categories?.categories['C'] ?? [],
              'D': dashboard.categories?.categories['D'] ?? [],
            };

            categoryMap.forEach((catLabel, clients) {
              for (final client in clients) {
                final daysRemaining = (client.avgPaymentDays ?? 0).toInt();
                allEmails.add({
                  'party': client.party,
                  'category': catLabel,
                  'email': '',
                  'closing_balance': 0.0,
                  'sales_amount': 0.0,
                  'days_remaining': daysRemaining,
                  'expected_date': null,
                  'discount_percent': client.discount,
                  'status': 'no_email',
                  'sent_date': null,
                  'opened': false,
                });
              }
            });
          }

          // Filter by selected category
          final filteredEmails = _selectedCategory == 'All'
              ? allEmails
              : allEmails.where((e) => e['category'] == _selectedCategory).toList();

          // Filter by tab
          final tabFiltered = filteredEmails.where((e) {
            if (_selectedTab == 'ready') return e['status'] == 'ready' || e['status'] == 'no_email';
            if (_selectedTab == 'sent') return e['sent_date'] != null;
            if (_selectedTab == 'failed') return e['status'] == 'failed';
            return true;
          }).toList();

          // Calculate stats
          int readyCount = allEmails.where((e) => e['status'] == 'ready').length;
          int noEmailCount = allEmails.where((e) => e['status'] == 'no_email').length;
          int sentCount = allEmails.where((e) => e['sent_date'] != null).length;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardDataProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Ready to Send',
                          count: readyCount,
                          color: Colors.green,
                          icon: Icons.mail_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Missing Email',
                          count: noEmailCount,
                          color: Colors.orange,
                          icon: Icons.warning_amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Sent',
                          count: sentCount,
                          color: AppStyles.primary,
                          icon: Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category Filter
                  Text(
                    'Filter by Category',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 24),

                  // Tab Selector
                  Row(
                    children: ['ready', 'sent', 'failed'].map((tab) {
                      final isSelected = _selectedTab == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = tab),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isSelected ? AppStyles.primary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              tab == 'ready' ? 'Ready' : tab == 'sent' ? 'Sent' : 'Failed',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppStyles.primary : AppStyles.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Email List
                  if (tabFiltered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.mail_outline, size: 48, color: AppStyles.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No emails in this category',
                              style: textTheme.bodyMedium?.copyWith(color: AppStyles.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tabFiltered.length,
                      itemBuilder: (context, index) {
                        final email = tabFiltered[index];
                        final category = email['category'] as String? ?? 'Unknown';
                        final color = _getCategoryColor(category);
                        final icon = _getCategoryIcon(category);
                        final hasEmail = (email['email'] as String? ?? '').isNotEmpty;

                        return GestureDetector(
                          onTap: () => _showEmailDetail(context, email),
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
                                            email['party'] as String,
                                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hasEmail ? email['email'] : '⚠️ No email available',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: hasEmail ? AppStyles.grey : Colors.red,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (email['sent_date'] != null)
                                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    if (email['opened'] == true)
                                      Tooltip(
                                        message: 'Email opened',
                                        child: Icon(Icons.visibility, color: AppStyles.primary, size: 20),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Details Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Amount Due',
                                          style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(email['closing_balance'] as double),
                                          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Expected Date',
                                          style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (email['expected_date'] as String?) ?? 'N/A',
                                          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Days Left',
                                          style: textTheme.labelSmall?.copyWith(color: AppStyles.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(email['days_remaining'] as int?) ?? 0} days',
                                          style: textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: (email['days_remaining'] as int) <= 0 ? Colors.red : AppStyles.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Action Buttons
                                Row(
                                  children: [
                                    if (!hasEmail)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showAddEmailDialog(context, email),
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Add Email'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _sendEmail(context, email),
                                          icon: const Icon(Icons.send, size: 18),
                                          label: const Text('Send'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _showEmailDetail(context, email),
                                      icon: const Icon(Icons.info_outline, size: 18),
                                      label: const Text('Details'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
          child: Text('Error loading emails: $error'),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppStyles.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailDetail(BuildContext context, Map<String, dynamic> email) {
    final category = email['category'] as String? ?? 'Unknown';
    final color = _getCategoryColor(category);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email['party'] as String? ?? 'Unknown Party',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${email['email'] ?? 'Not provided'}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
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
                    _buildDetailRow('Amount Due', _formatCurrency((email['closing_balance'] as num?)?.toDouble() ?? 0)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Sales/Receipts', _formatCurrency((email['sales_amount'] as num?)?.toDouble() ?? 0)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Discount', '${((email['discount_percent'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Expected Date', email['expected_date'] as String? ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Days Remaining', '${email['days_remaining']} days'),
                    const SizedBox(height: 20),

                    // Template Preview
                    Text(
                      'Email Template Preview',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppStyles.divider.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getEmailTemplate(category),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _sendEmail(context, email);
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Send Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppStyles.grey,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAddEmailDialog(BuildContext context, Map<String, dynamic> email) {
    final controller = TextEditingController();
    final transactionService = ref.read(transactionServiceProvider);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Email for ${email['party']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Send discount offer immediately'),
                value: true,
                onChanged: null, // Always checked
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (controller.text.isNotEmpty && controller.text.contains('@')) {
                        setState(() => isLoading = true);
                        try {
                          // Save email to backend
                          final response = await transactionService.savePartyEmail(
                            partyName: email['party'] as String,
                            email: controller.text,
                            sendEmail: true, // Always send when adding email
                          );

                          if (response['status'] == 'success') {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  response['email_sent'] == true
                                      ? 'Email saved and discount offer sent!'
                                      : 'Email saved successfully',
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            // Refresh dashboard data
                            ref.refresh(dashboardDataProvider);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${response['message'] ?? 'Unknown error'}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving email: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email address'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmail(BuildContext context, Map<String, dynamic> email) {
    // Don't send if no email available
    if ((email['email'] as String? ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add an email address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog before sending
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Email?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send discount offer email to ${email['party']}?'),
            const SizedBox(height: 8),
            Text(
              'Email: ${email['email']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Discount Value: ₹${email['discount_amount'] is num ? (email['discount_amount'] as num).toStringAsFixed(0) : '0'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
              final transactionService = ref.read(transactionServiceProvider);

              try {
                // Send email via backend
                final response = await transactionService.sendEmailToParty(
                  partyName: email['party'] as String,
                  email: email['email'] as String,
                  subject: 'Early Payment Discount Offer - Save ₹${email['discount_amount'] is num ? (email['discount_amount'] as num).toStringAsFixed(0) : '0'}',
                  body: _getEmailTemplate(email['category'] as String? ?? 'D'),
                  discountDetails: {
                    'closing_balance': email['closing_balance'],
                    'discount_amount': email['discount_amount'],
                    'discount_pct': email['discount_percent'],
                    'expected_payment_date': email['expected_date'],
                    'days_remaining': email['days_remaining'],
                  },
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Email sent successfully!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // Refresh dashboard
                  ref.refresh(dashboardDataProvider);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class EmailDraftScreen extends ConsumerStatefulWidget {
  final String? partyId;

  const EmailDraftScreen({
    this.partyId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<EmailDraftScreen> createState() => _EmailDraftScreenState();
}

class _EmailDraftScreenState extends ConsumerState<EmailDraftScreen> {
  late TextEditingController _toController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  bool _includeDiscount = true;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: '${widget.partyId}@company.com');
    _subjectController = TextEditingController(
      text: 'Payment Reminder - Outstanding Invoice',
    );
    _bodyController = TextEditingController(
      text: 'Dear ${widget.partyId},\n\nWe hope this email finds you well.\n\nWe have an outstanding invoice for ₹5.2L due on ${DateTime.now().add(Duration(days: 10)).toString().split(' ')[0]}.\n\nIf you pay within 7 days, we offer a 2% discount.\n\nBest regards,\nFinance Team',
    );
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Draft'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // To
            Text(
              'To',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _toController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // Subject
            Text(
              'Subject',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // Body
            Text(
              'Message',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Email body',
              ),
              maxLines: 10,
            ),
            const SizedBox(height: 16),

            // Discount Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discount Mention Included',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '2% if paid within 7 days',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send via Email'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email sent successfully!')),
                  );
                  context.go('/email');
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
