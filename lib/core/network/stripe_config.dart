import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';

/// Stripe Configuration for AuraTry App
///
/// Fix 9: Replace the placeholder keys below with your real Stripe keys.
/// Get them from https://dashboard.stripe.com/test/apikeys
///
/// NEVER commit real keys to version control.
/// For production builds use --dart-define or a secrets manager.

class StripeConfig {
  // =================================================================
  // STRIPE KEYS — REPLACE THESE WITH YOUR REAL KEYS
  // =================================================================

  /// Test publishable key — starts with pk_test_
  /// Get from: https://dashboard.stripe.com/test/apikeys
  static const String publishableKeyTest =
      String.fromEnvironment(
        'STRIPE_PK_TEST',
        // Replace the line below with your actual test key:
        defaultValue: 'pk_test_51T1Ozd8bLYbogZQ1qMGm0TbyzlvN7d7zGxj9bujs2lxo9RXPMKfbcTvRrxzG4hj2kSMOT9H86nSudjMKgLAn87HC00SwYYI5U1',
      );

  /// Live publishable key — starts with pk_live_
  /// Only used when useTestMode = false
  static const String publishableKeyLive =
      String.fromEnvironment(
        'STRIPE_PK_LIVE',
        defaultValue: 'pk_live_51T1Ozd8bLYbogZQ1qMGm0TbyzlvN7d7zGxj9bujs2lxo9RXPMKfbcTvRrxzG4hj2kSMOT9H86nSudjMKgLAn87HC00SwYYI5U1',
      );

  static const String merchantDisplayName = 'AuraTry';
  static const String defaultCurrency = 'inr';

  /// Set to false when going to production
  static const bool useTestMode = true;

  static String get publishableKey =>
      useTestMode ? publishableKeyTest : publishableKeyLive;

  // =================================================================
  // INITIALIZATION — called in main.dart before runApp()
  // =================================================================
  static Future<void> init() async {
    try {
      Stripe.publishableKey = publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.auratry';
      await Stripe.instance.applySettings();
      debugPrint(
          '✅ Stripe initialised in ${useTestMode ? 'TEST' : 'LIVE'} mode');
    } catch (e) {
      debugPrint('❌ Stripe init failed: $e');
      // Rethrow so main() surfaces the error clearly
      rethrow;
    }
  }

  // =================================================================
  // PAYMENT SHEET
  // =================================================================
  static SetupPaymentSheetParameters getPaymentSheetParameters({
    required String paymentIntentClientSecret,
    String? customerEphemeralKeySecret,
    String? customerId,
  }) {
    return SetupPaymentSheetParameters(
      paymentIntentClientSecret: paymentIntentClientSecret,
      merchantDisplayName: merchantDisplayName,
      customerEphemeralKeySecret: customerEphemeralKeySecret,
      customerId: customerId,
      style: ThemeMode.light,
      applePay: const PaymentSheetApplePay(
        merchantCountryCode: 'IN',
      ),
      googlePay: PaymentSheetGooglePay(
        merchantCountryCode: 'IN',
        testEnv: useTestMode,
        currencyCode: defaultCurrency,
      ),
    );
  }

  static Future<bool> presentPaymentSheet({
    required String clientSecret,
    String? customerEphemeralKeySecret,
    String? customerId,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: getPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          customerId: customerId,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      debugPrint('✅ Stripe payment completed');
      return true;
    } on StripeException catch (e) {
      debugPrint('❌ Stripe error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('❌ Payment error: $e');
      return false;
    }
  }

  // =================================================================
  // HELPERS
  // =================================================================
  static int amountToPaise(double amount) => (amount * 100).round();
  static double paiseToAmount(int paise) => paise / 100;

  static String formatAmount(double amount,
          {String currencySymbol = '₹'}) =>
      '$currencySymbol${amount.toStringAsFixed(2)}';

  static bool isValidCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static bool isValidExpiryDate(String expiry) {
    final parts = expiry.split('/');
    if (parts.length != 2) return false;
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    final fullYear = year < 100 ? 2000 + year : year;
    return DateTime(fullYear, month).isAfter(DateTime.now());
  }

  static bool isValidCVV(String cvv, {String? cardBrand}) {
    if (cardBrand == 'American Express') {
      return cvv.length == 4 && RegExp(r'^\d{4}$').hasMatch(cvv);
    }
    return cvv.length == 3 && RegExp(r'^\d{3}$').hasMatch(cvv);
  }

  // =================================================================
  // TEST CARDS (development only)
  // =================================================================
  static List<Map<String, String>> get testCards => [
        {
          'name': 'Successful Payment',
          'number': '4242 4242 4242 4242',
          'description': 'Always succeeds'
        },
        {
          'name': 'Declined Payment',
          'number': '4000 0000 0000 0002',
          'description': 'Always declined'
        },
        {
          'name': 'Requires Authentication',
          'number': '4000 0025 0000 3155',
          'description': 'Requires 3D Secure'
        },
        {
          'name': 'Insufficient Funds',
          'number': '4000 0000 0000 9995',
          'description': 'Declined — insufficient funds'
        },
      ];
}