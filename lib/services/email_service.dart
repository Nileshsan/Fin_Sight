import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import '../config/app_config.dart';

final logger = Logger();

class EmailTemplate {
  final String to;
  final String partyName;
  final Map<String, dynamic> discountDetails;
  final String htmlContent;

  EmailTemplate({
    required this.to,
    required this.partyName,
    required this.discountDetails,
    required this.htmlContent,
  });

  factory EmailTemplate.fromJson(Map<String, dynamic> json) {
    return EmailTemplate(
      to: json['to'] ?? '',
      partyName: json['party_name'] ?? '',
      discountDetails: json['discount_details'] ?? {},
      htmlContent: json['html_content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'to': to,
      'party_name': partyName,
      'discount_details': discountDetails,
      'html_content': htmlContent,
    };
  }
}

class EmailService {
  final Dio _dio;
  
  // Get base URL from AppConfig - never hardcode
  static String get baseUrl => '${AppConfig.djangoBaseUrl}/api';

  EmailService({required Dio dio}) : _dio = dio;

  /// Get email templates ready to send
  Future<List<EmailTemplate>> getEmailTemplates() async {
    try {
      logger.i('[EMAIL] Fetching email templates...');

      final response = await _dio.get(
        '$baseUrl/live/emails/',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        logger.i('[EMAIL] ✅ Email templates retrieved successfully');

        if (data is Map<String, dynamic>) {
          final emails = data['emails'] ?? [];
          if (emails is List) {
            return emails
                .map((e) => EmailTemplate.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      } else {
        throw Exception('Failed to fetch email templates: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('[EMAIL] ❌ Dio error fetching templates: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      logger.e('[EMAIL] ❌ Error fetching email templates: $e');
      rethrow;
    }
  }

  /// Send discount emails
  Future<Map<String, dynamic>> sendEmails(
    List<Map<String, dynamic>> emails,
  ) async {
    try {
      logger.i('[EMAIL] Sending ${emails.length} emails...');

      final response = await _dio.post(
        '$baseUrl/live/emails/send/',
        data: {'emails': emails},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final result = response.data as Map<String, dynamic>;
        logger.i(
          '[EMAIL] ✅ Emails sent successfully! '
          'Sent: ${result['results']['sent']}, Failed: ${result['results']['failed']}',
        );
        return result;
      } else {
        throw Exception('Failed to send emails: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('[EMAIL] ❌ Dio error sending emails: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      logger.e('[EMAIL] ❌ Error sending emails: $e');
      rethrow;
    }
  }

  /// Save party email
  Future<bool> savePartyEmail(String partyName, String email) async {
    try {
      logger.i('[EMAIL] Saving email for $partyName: $email');

      final response = await _dio.post(
        '$baseUrl/live/emails/save/',
        data: {
          'party_name': partyName,
          'email': email,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        logger.i('[EMAIL] ✅ Email saved successfully for $partyName');
        return true;
      } else {
        throw Exception('Failed to save email: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('[EMAIL] ❌ Dio error saving email: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      logger.e('[EMAIL] ❌ Error saving email: $e');
      rethrow;
    }
  }
}
