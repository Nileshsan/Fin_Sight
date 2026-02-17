import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/email_service.dart';
import '../../providers/email_provider.dart';

class EmailManagementScreen extends ConsumerStatefulWidget {
  const EmailManagementScreen({super.key});

  @override
  ConsumerState<EmailManagementScreen> createState() =>
      _EmailManagementScreenState();
}

class _EmailManagementScreenState extends ConsumerState<EmailManagementScreen> {
  final Set<int> selectedEmails = {};
  late WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    final emailTemplates = ref.watch(emailTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Management'),
        backgroundColor: const Color(0xFF66BB6A),
        centerTitle: true,
      ),
      body: emailTemplates.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No emails to send',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate discount offers to send emails',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header with selection info
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${templates.length} | Selected: ${selectedEmails.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (selectedEmails.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() => selectedEmails.clear());
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: const Color(0xFF66BB6A),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Email list
              Expanded(
                child: ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final isSelected = selectedEmails.contains(index);

                    return EmailTile(
                      template: template,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedEmails.remove(index);
                          } else {
                            selectedEmails.add(index);
                          }
                        });
                      },
                      onPreview: () {
                        _showEmailPreview(context, template);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading emails',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.refresh(emailTemplatesProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                  ),
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: selectedEmails.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _sendSelectedEmails(context, ref),
              backgroundColor: const Color(0xFF66BB6A),
              icon: const Icon(Icons.send),
              label: Text('Send (${selectedEmails.length})'),
            )
          : null,
    );
  }

  void _showEmailPreview(BuildContext context, EmailTemplate template) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFF66BB6A),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To: ${template.to}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Email content
            Expanded(
              child: WebView(
                initialUrl:
                    'data:text/html;base64,${Uri.encodeComponent(template.htmlContent)}',
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSelectedEmails(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final emailTemplates = ref.read(emailTemplatesProvider);

    emailTemplates.whenData((templates) async {
      final emailsToSend = selectedEmails
          .map((index) => templates[index])
          .map((template) => {
                'to': template.to,
                'party_name': template.partyName,
                'discount_details': template.discountDetails,
              })
          .toList();

      // Show confirmation dialog
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Send Emails?'),
          content: Text(
            'Send ${emailsToSend.length} email(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Send emails
      try {
        final result = await ref.read(emailServiceProvider).sendEmails(
              emailsToSend,
            );

        if (!context.mounted) return;

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Emails Sent'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Successfully sent: ${result['results']['sent']}/${result['total']}',
                ),
                if (result['results']['failed'] > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Failed: ${result['results']['failed']}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Clear selection and refresh
        setState(() => selectedEmails.clear());
        ref.refresh(emailTemplatesProvider);
      } catch (e) {
        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }
}

class EmailTile extends StatelessWidget {
  final EmailTemplate template;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const EmailTile({
    required this.template,
    required this.isSelected,
    required this.onTap,
    required this.onPreview,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final discountAmount =
        template.discountDetails['discount_amount']?.toString() ?? '0';
    final discountPercent =
        template.discountDetails['total_discount']?.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Material(
        color: isSelected ? const Color(0xFF66BB6A).withOpacity(0.1) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  fillColor: MaterialStateProperty.all(const Color(0xFF66BB6A)),
                  checkColor: Colors.white,
                ),
                const SizedBox(width: 12),
                // Email info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.partyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.to,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '💰 Save ₹$discountAmount ($discountPercent%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Preview button
                IconButton(
                  onPressed: onPreview,
                  icon: const Icon(
                    Icons.preview,
                    color: Color(0xFF66BB6A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
