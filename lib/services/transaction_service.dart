import 'package:logger/logger.dart';
import 'api_service.dart';

/// Models for LIVE analysis responses
class CashflowPrediction {
  final String date;
  final double predictedBalance;
  final double receipts;
  final double expenses;
  final double minBalance;
  final double maxBalance;
  final double confidence;

  CashflowPrediction({
    required this.date,
    required this.predictedBalance,
    required this.receipts,
    required this.expenses,
    required this.minBalance,
    required this.maxBalance,
    required this.confidence,
  });

  factory CashflowPrediction.fromJson(Map<String, dynamic> json) {
    return CashflowPrediction(
      date: json['date'] ?? '',
      predictedBalance: (json['predicted_balance'] ?? 0).toDouble(),
      receipts: (json['receipts'] ?? 0).toDouble(),
      expenses: (json['expenses'] ?? 0).toDouble(),
      minBalance: (json['min_balance'] ?? 0).toDouble(),
      maxBalance: (json['max_balance'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0.5).toDouble(),
    );
  }
}

class CashflowResponse {
  final String status;
  final List<CashflowPrediction> predictions;
  final Map<String, dynamic> summary;

  CashflowResponse({
    required this.status,
    required this.predictions,
    required this.summary,
  });

  factory CashflowResponse.fromJson(Map<String, dynamic> json) {
    // Extract predictions from cashflow_forecast or fallback to predictions
    List<CashflowPrediction> predictions = [];
    final forecastData = json['cashflow_forecast'] as Map<String, dynamic>?;
    
    if (forecastData != null && forecastData['predictions'] is List) {
      predictions = (forecastData['predictions'] as List<dynamic>)
          .map((p) => CashflowPrediction.fromJson(p as Map<String, dynamic>))
          .toList();
    } else if (json['predictions'] is List) {
      predictions = (json['predictions'] as List<dynamic>)
          .map((p) => CashflowPrediction.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    
    // Get status from cashflow_forecast or root
    String status = 'success';
    if (forecastData != null && forecastData['status'] != null) {
      status = forecastData['status'] ?? 'success';
    } else {
      status = json['status'] ?? 'success';
    }
    
    return CashflowResponse(
      status: status,
      predictions: predictions.isNotEmpty ? predictions : [_createDefaultPrediction()],
      summary: json['summary'] ?? forecastData ?? {},
    );
  }
  
  static CashflowPrediction _createDefaultPrediction() {
    return CashflowPrediction(
      date: 'N/A',
      predictedBalance: 0,
      receipts: 0,
      expenses: 0,
      minBalance: 0,
      maxBalance: 0,
      confidence: 0,
    );
  }
}

class ClientCategory {
  final String party;
  final double? avgPaymentDays;
  final double discount;
  final int paymentCount;
  final double reliability;
  final String category;

  ClientCategory({
    required this.party,
    this.avgPaymentDays,
    required this.discount,
    required this.paymentCount,
    required this.reliability,
    required this.category,
  });

  factory ClientCategory.fromJson(Map<String, dynamic> json) {
    return ClientCategory(
      party: json['party'] ?? 'Unknown',
      avgPaymentDays: json['avg_payment_days']?.toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      paymentCount: json['payment_count'] ?? 0,
      reliability: (json['reliability'] ?? 0).toDouble(),
      category: json['category'] ?? 'D',
    );
  }
}

class CategoriesResponse {
  final String status;
  final Map<String, List<ClientCategory>> categories;
  final Map<String, dynamic> summary;

  CategoriesResponse({
    required this.status,
    required this.categories,
    required this.summary,
  });

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    final categories = <String, List<ClientCategory>>{};
    
    // First, try to parse from classifications (flat map of party: category)
    final classifications = json['classifications'] as Map<String, dynamic>? ?? {};
    final clientAnalysis = json['client_analysis'] as Map<String, dynamic>? ?? {};
    
    // Group parties by their category (A, B, C, D)
    final categoryMap = <String, List<ClientCategory>>{};
    
    if (classifications.isNotEmpty) {
      for (final entry in classifications.entries) {
        final party = entry.key;
        final categoryLetter = entry.value?.toString() ?? 'D';
        
        // Get detailed data from client_analysis if available
        final clientDetails = clientAnalysis[party] as Map<String, dynamic>? ?? {};
        
        final clientCategory = ClientCategory(
          party: party,
          avgPaymentDays: (clientDetails['payment_metrics']?['avg_payment_days'] as num?)?.toDouble(),
          discount: 0.0,
          paymentCount: clientDetails['performance']?['total_transactions'] ?? 0,
          reliability: ((clientDetails['performance']?['reliability_score'] as num?)?.toDouble() ?? 0) / 100,
          category: categoryLetter,
        );
        
        // Group by category
        if (!categoryMap.containsKey(categoryLetter)) {
          categoryMap[categoryLetter] = [];
        }
        categoryMap[categoryLetter]!.add(clientCategory);
      }
    }
    
    // If no classifications, try to parse from categories field
    if (categoryMap.isEmpty) {
      final categoriesData = json['categories'] as Map<String, dynamic>? ?? {};
      for (final entry in categoriesData.entries) {
        categoryMap[entry.key] = (entry.value as List<dynamic>?)
                ?.map((c) => ClientCategory.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [];
      }
    }
    
    return CategoriesResponse(
      status: json['status'] ?? 'success',
      categories: categoryMap.isEmpty ? {'A': [], 'B': [], 'C': [], 'D': []} : categoryMap,
      summary: json['summary'] ?? {'total_clients': classifications.length},
    );
  }
}

class DiscountOffer {
  final String party;
  final double salesAmount;
  final double closingBalance;
  final String? expectedPaymentDate;
  final int daysRemaining;
  final String category;
  final double categoryDiscount;
  final double timeValueDiscount;
  final double totalDiscount;
  final double discountAmount;
  final double amountIfPaidToday;
  final String emailSubject;
  final String? clientEmail;
  final List<Map<String, dynamic>> unpaidSales;
  final int unpaidSalesCount;

  DiscountOffer({
    required this.party,
    required this.salesAmount,
    required this.closingBalance,
    this.expectedPaymentDate,
    required this.daysRemaining,
    required this.category,
    required this.categoryDiscount,
    required this.timeValueDiscount,
    required this.totalDiscount,
    required this.discountAmount,
    required this.amountIfPaidToday,
    required this.emailSubject,
    this.clientEmail,
    this.unpaidSales = const [],
    this.unpaidSalesCount = 0,
  });

  factory DiscountOffer.fromJson(Map<String, dynamic> json) {
    return DiscountOffer(
      party: json['party'] ?? 'Unknown',
      salesAmount: (json['sales_amount'] ?? 0).toDouble(),
      closingBalance: (json['closing_balance'] ?? 0).toDouble(),
      expectedPaymentDate: json['expected_payment_date'],
      daysRemaining: json['days_remaining'] ?? 0,
      category: json['category'] ?? json['category_discount'] ?? 'C',  // Handle if category comes as discount value
      categoryDiscount: (json['category_discount'] ?? 0).toDouble(),
      timeValueDiscount: (json['time_value_discount'] ?? 0).toDouble(),
      totalDiscount: (json['total_discount_pct'] ?? json['total_discount'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      amountIfPaidToday: (json['amount_if_paid_today'] ?? 0).toDouble(),
      emailSubject: json['email_subject'] ?? '',
      clientEmail: json['client_email'],
      unpaidSales: (json['unpaid_sales'] as List<dynamic>?)
              ?.map((e) => (e as Map<String, dynamic>))
              .toList() ??
          [],
      unpaidSalesCount: json['unpaid_sales_count'] ?? 0,
    );
  }
}

class DiscountsResponse {
  final String status;
  final String date;
  final List<DiscountOffer> discounts;
  final Map<String, dynamic> summary;

  DiscountsResponse({
    required this.status,
    required this.date,
    required this.discounts,
    required this.summary,
  });

  factory DiscountsResponse.fromJson(Map<String, dynamic> json) {
    // Handle both formats: direct list or offers field
    List<DiscountOffer> discounts = [];
    
    // Try to get from 'offers' field first (newer format)
    if (json['offers'] is List) {
      discounts = (json['offers'] as List<dynamic>)
          .map((d) => DiscountOffer.fromJson(d as Map<String, dynamic>))
          .toList();
    } 
    // Fallback to 'discounts' field (older format)
    else if (json['discounts'] is List) {
      discounts = (json['discounts'] as List<dynamic>)
          .map((d) => DiscountOffer.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    
    return DiscountsResponse(
      status: json['status'] ?? 'success',
      date: json['date'] ?? DateTime.now().toString().split(' ')[0],
      discounts: discounts,
      summary: json['summary'] ?? {'total_offers': 0},
    );
  }
}

class EmailTemplate {
  final String to;
  final String partyName;
  final String subject;
  final String body;
  final Map<String, dynamic> discountDetails;
  final bool readyToSend;

  EmailTemplate({
    required this.to,
    required this.partyName,
    required this.subject,
    required this.body,
    required this.discountDetails,
    required this.readyToSend,
  });

  factory EmailTemplate.fromJson(Map<String, dynamic> json) {
    return EmailTemplate(
      to: json['to'] ?? 'unknown@example.com',
      partyName: json['party_name'] ?? 'Unknown',
      subject: json['subject'] ?? 'Email',
      body: json['body'] ?? '',
      discountDetails: json['discount_details'] ?? {},
      readyToSend: json['ready_to_send'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'to': to,
      'party_name': partyName,
      'subject': subject,
      'body': body,
      'discount_details': discountDetails,
      'ready_to_send': readyToSend,
    };
  }
}

class EmailsResponse {
  final String status;
  final List<EmailTemplate> emails;
  final Map<String, dynamic> summary;

  EmailsResponse({
    required this.status,
    required this.emails,
    required this.summary,
  });

  factory EmailsResponse.fromJson(Map<String, dynamic> json) {
    final emails = (json['emails'] as List<dynamic>?)
            ?.map((e) => EmailTemplate.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return EmailsResponse(
      status: json['status'] ?? 'unknown',
      emails: emails,
      summary: json['summary'] ?? {},
    );
  }
}

/// Represents a single party with its complete financial data
class PartyData {
  final String partyName;
  final String party;
  final String category;
  final double closingBalance;
  final double discountAmount;
  final double discountPct;
  final String? clientEmail;
  final bool hasEmail;
  final bool canAddEmail;
  final int daysRemaining;
  final String predictedPaymentDate;
  final int avgPaymentDays;
  final int unpaidSalesCount;

  PartyData({
    required this.partyName,
    required this.party,
    required this.category,
    required this.closingBalance,
    required this.discountAmount,
    required this.discountPct,
    this.clientEmail,
    this.hasEmail = false,
    this.canAddEmail = true,
    this.daysRemaining = 0,
    this.predictedPaymentDate = 'N/A',
    this.avgPaymentDays = 30,
    this.unpaidSalesCount = 0,
  });

  factory PartyData.fromJson(Map<String, dynamic> json) {
    return PartyData(
      partyName: json['party_name'] ?? json['party'] ?? 'Unknown',
      party: json['party'] ?? json['party_name'] ?? 'Unknown',
      category: json['category'] ?? 'D',
      closingBalance: (json['closing_balance'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      discountPct: (json['discount_pct'] ?? 0).toDouble(),
      clientEmail: json['client_email'],
      hasEmail: json['has_email'] ?? false,
      canAddEmail: json['can_add_email'] ?? true,
      daysRemaining: json['days_remaining'] ?? 0,
      predictedPaymentDate: json['predicted_payment_date'] ?? 'N/A',
      avgPaymentDays: json['avg_payment_days'] ?? 30,
      unpaidSalesCount: json['unpaid_sales_count'] ?? 0,
    );
  }
}

class UnifiedDashboardResponse {
  final String status;
  final int companyId;
  final String generatedAt;
  final CashflowResponse cashflow;
  final CategoriesResponse categories;
  final DiscountsResponse discounts;
  final EmailsResponse emails;
  final List<PartyData> parties;
  final int partiesCount;

  UnifiedDashboardResponse({
    required this.status,
    required this.companyId,
    required this.generatedAt,
    required this.cashflow,
    required this.categories,
    required this.discounts,
    required this.emails,
    this.parties = const [],
    this.partiesCount = 0,
  });

  factory UnifiedDashboardResponse.fromJson(Map<String, dynamic> json) {
    List<PartyData> partiesList = [];
    if (json['parties'] is List) {
      partiesList = (json['parties'] as List<dynamic>)
          .map((p) => PartyData.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return UnifiedDashboardResponse(
      status: json['status'] ?? 'unknown',
      companyId: json['company_id'] ?? 0,
      generatedAt: json['generated_at'] ?? 'Unknown',
      cashflow: CashflowResponse.fromJson(
          json['cashflow'] as Map<String, dynamic>? ?? {}),
      categories: CategoriesResponse.fromJson(
          json['categories'] as Map<String, dynamic>? ?? {}),
      discounts: DiscountsResponse.fromJson(
          json['discounts'] as Map<String, dynamic>? ?? {}),
      emails: EmailsResponse.fromJson(
          json['emails'] as Map<String, dynamic>? ?? {}),
      parties: partiesList,
      partiesCount: json['parties_count'] ?? partiesList.length,
    );
  }
}

/// Service for LIVE analysis endpoints
class TransactionService {
  final ApiService apiService;
  final Logger logger;

  TransactionService({
    required this.apiService,
    Logger? logger,
  }) : logger = logger ?? Logger();

  /// Get LIVE cashflow predictions
  Future<CashflowResponse> getLiveCashflow({int days = 90}) async {
    try {
      logger.i('[API] Fetching LIVE cashflow predictions...');
      final data = await apiService.get<Map<String, dynamic>>(
        'transactions/live/cashflow/',
        queryParameters: {'days': days},
        fromJson: (json) => json,
      );
      return CashflowResponse.fromJson(data);
    } catch (e) {
      logger.e('[API] Error fetching cashflow: $e');
      rethrow;
    }
  }

  /// Get LIVE client categories
  Future<CategoriesResponse> getLiveCategories() async {
    try {
      logger.i('[API] Fetching LIVE client categories...');
      final data = await apiService.get<Map<String, dynamic>>(
        'transactions/live/categories/',
        fromJson: (json) => json,
      );
      return CategoriesResponse.fromJson(data);
    } catch (e) {
      logger.e('[API] Error fetching categories: $e');
      rethrow;
    }
  }

  /// Get LIVE discount offers (TODAY only)
  Future<DiscountsResponse> getLiveDiscounts() async {
    try {
      logger.i('[API] Fetching LIVE discount offers for TODAY...');
      final data = await apiService.get<Map<String, dynamic>>(
        'transactions/live/discounts/',
        fromJson: (json) => json,
      );
      return DiscountsResponse.fromJson(data);
    } catch (e) {
      logger.e('[API] Error fetching discounts: $e');
      rethrow;
    }
  }

  /// Get email templates (LIVE)
  Future<EmailsResponse> getEmailTemplates() async {
    try {
      logger.i('[API] Fetching LIVE email templates...');
      final data = await apiService.get<Map<String, dynamic>>(
        'transactions/live/emails/',
        fromJson: (json) => json,
      );
      return EmailsResponse.fromJson(data);
    } catch (e) {
      logger.e('[API] Error fetching emails: $e');
      rethrow;
    }
  }

  /// Send discount emails
  Future<Map<String, dynamic>> sendEmails({
    required List<Map<String, dynamic>> emails,
  }) async {
    try {
      logger.i('[API] Sending ${emails.length} discount emails...');
      final response = await apiService.post<Map<String, dynamic>>(
        'transactions/live/emails/send/',
        data: {'emails': emails},
        fromJson: (json) => json,
      );
      return response;
    } catch (e) {
      logger.e('[API] Error sending emails: $e');
      rethrow;
    }
  }

  /// Get unified dashboard (all 4 analyses at once)
  Future<UnifiedDashboardResponse> getUnifiedDashboard({int days = 90}) async {
    try {
      logger.i('[API] Fetching UNIFIED LIVE dashboard...');
      final data = await apiService.get<Map<String, dynamic>>(
        'transactions/live/dashboard/',
        queryParameters: {'days': days},
        fromJson: (json) => json,
      );
      try {
        // Log a short summary of the raw response for debugging
        logger.d('TransactionService:getUnifiedDashboard - raw response keys: ${data.keys.toList()}');
      } catch (_) {}
      return UnifiedDashboardResponse.fromJson(data);
    } catch (e) {
      logger.e('[API] Error fetching dashboard: $e');
      rethrow;
    }
  }

  /// Check if new data is available on the server (lightweight endpoint)
  /// Returns the timestamp of the latest data generation
  Future<Map<String, dynamic>> checkForDataUpdates() async {
    try {
      logger.i('[API] Checking for data updates...');
      final response = await apiService.get<Map<String, dynamic>>(
        'transactions/live/dashboard/check-updates/',
        fromJson: (json) => json,
      );
      return response;
    } catch (e) {
      logger.e('[API] Error checking for updates: $e');
      // Return empty map on error - no new data assumed
      return {'has_updates': false, 'message': 'Could not check updates'};
    }
  }

  /// Save party email and optionally send discount offer
  Future<Map<String, dynamic>> savePartyEmail({
    required String partyName,
    required String email,
    bool sendEmail = true,
  }) async {
    try {
      logger.i('[API] Saving email for $partyName: $email (send_email=$sendEmail)');
      final response = await apiService.post<Map<String, dynamic>>(
        'live/emails/save/',
        data: {
          'party_name': partyName,
          'email': email,
          'send_email': sendEmail,
        },
        fromJson: (json) => json,
      );
      return response;
    } catch (e) {
      logger.e('[API] Error saving email: $e');
      rethrow;
    }
  }

  /// Send email to a party
  Future<Map<String, dynamic>> sendEmailToParty({
    required String partyName,
    required String email,
    required String subject,
    required String body,
    Map<String, dynamic>? discountDetails,
  }) async {
    try {
      logger.i('[API] Sending email to $email');
      final response = await apiService.post<Map<String, dynamic>>(
        'live/emails/send/',
        data: {
          'to': email,
          'party_name': partyName,
          'subject': subject,
          'body': body,
          'discount_details': discountDetails,
        },
        fromJson: (json) => json,
      );
      return response;
    } catch (e) {
      logger.e('[API] Error sending email: $e');
      rethrow;
    }
  }
}
