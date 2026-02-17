import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/email_service.dart';
import '../services/api_service.dart';

// Email Service Provider
final emailServiceProvider = Provider<EmailService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EmailService(dio: apiService.dio);
});

// Get email templates
final emailTemplatesProvider = FutureProvider<List<EmailTemplate>>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  return await emailService.getEmailTemplates();
});

// Send emails
final sendEmailsProvider =
    FutureProvider.family<Map<String, dynamic>, List<Map<String, dynamic>>>((
  ref,
  emails,
) async {
  final emailService = ref.watch(emailServiceProvider);
  return await emailService.sendEmails(emails);
});

// Save party email
final savePartyEmailProvider =
    FutureProvider.family<bool, (String, String)>((ref, params) async {
  final emailService = ref.watch(emailServiceProvider);
  return await emailService.savePartyEmail(params.$1, params.$2);
});
