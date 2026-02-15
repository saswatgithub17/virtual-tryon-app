import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';

/// Stripe Configuration for AuraTry App
/// Location: lib/config/stripe_config.dart
///
/// This integrates with your existing payment_provider.dart
///
/// Setup Instructions:
/// 1. Get Stripe API keys from https://dashboard.stripe.com
/// 2. Replace the keys below
/// 3. Uncomment the init() call in main.dart
/// 4. Configure backend with secret key

class StripeConfig {
  // =================================================================
  // STRIPE KEYS - REPLACE WITH YOUR ACTUAL KEYS
  // =================================================================

  /// Test Publishable Key (starts with pk_test_)
  /// Get from: https://dashboard.stripe.com/test/apikeys
  static const String publishableKeyTest =
      'pk_test_51QmYourTestKeyHere'; // REPLACE THIS

  /// Live Publishable Key (starts with pk_live_)
  /// Get from: https://dashboard.stripe.com/apikeys
  /// ONLY use in production!
  static const String publishableKeyLive =
      'pk_live_51QmYourLiveKeyHere'; // REPLACE THIS

  /// Merchant Display Name
  static const String merchantDisplayName = 'AuraTry';

  /// Default Currency
  static const String defaultCurrency = 'usd';

  // =================================================================
  // CONFIGURATION
  // =================================================================

  /// Use test mode?
  /// Set to false in production
  static const bool useTestMode = true;

  /// Get current publishable key based on mode
  static String get publishableKey {
    return useTestMode ? publishableKeyTest : publishableKeyLive;
  }

  // =================================================================
  // INITIALIZATION
  // =================================================================

  /// Initialize Stripe
  /// Call this in main.dart before runApp()
  static Future<void> init() async {
    try {
      // Set publishable key
      Stripe.publishableKey = publishableKey;

      // Set merchant identifier (for Apple Pay)
      Stripe.merchantIdentifier = 'merchant.com.auratry';

      // Apply settings
      await Stripe.instance.applySettings();

      debugPrint(
          '✅ Stripe initialized in ${useTestMode ? 'TEST' : 'LIVE'} mode');
    } catch (e) {
      debugPrint('❌ Error initializing Stripe: $e');
      rethrow;
    }
  }

  // =================================================================
  // PAYMENT SHEET CONFIGURATION
  // =================================================================

  /// Get payment sheet parameters
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

      // Apple Pay configuration
      applePay: const PaymentSheetApplePay(
        merchantCountryCode: 'US',
      ),

      // Google Pay configuration
      googlePay: const PaymentSheetGooglePay(
        merchantCountryCode: 'US',
        testEnv: useTestMode,
        currencyCode: defaultCurrency,
      ),
    );
  }

  // =================================================================
  // PAYMENT METHODS
  // =================================================================

  /// Initialize and present payment sheet
  /// This is called from your PaymentProvider
  static Future<bool> presentPaymentSheet({
    required String clientSecret,
    String? customerEphemeralKeySecret,
    String? customerId,
  }) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: getPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          customerId: customerId,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('✅ Payment completed successfully');
      return true;
    } on StripeException catch (e) {
      debugPrint('❌ Stripe Error: ${e.error.localizedMessage}');
      // User cancelled or error occurred
      return false;
    } catch (e) {
      debugPrint('❌ Payment Error: $e');
      return false;
    }
  }

  /// Confirm payment (alternative method)
  static Future<bool> confirmPayment({
    required String clientSecret,
    required PaymentMethodParams paymentMethodParams,
  }) async {
    return false;
    // try {
    //   final paymentIntent = await Stripe.instance.confirmPayment(
    //     paymentIntentClientSecret: clientSecret,
    //     data: PaymentMethodParams(
    //       type: PaymentMethodType.Card,
    //       billingDetails: paymentMethodParams.billingDetails,
    //     ),
    //   );

    //   if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
    //     debugPrint('✅ Payment confirmed successfully');
    //     return true;
    //   } else {
    //     debugPrint('⚠️ Payment status: ${paymentIntent.status}');
    //     return false;
    //   }
    // } on StripeException catch (e) {
    //   debugPrint('❌ Stripe Error: ${e.error.localizedMessage}');
    //   return false;
    // } catch (e) {
    //   debugPrint('❌ Confirmation Error: $e');
    //   return false;
    // }
  }

  // =================================================================
  // HELPER METHODS
  // =================================================================

  /// Convert amount to cents (Stripe uses smallest currency unit)
  static int amountToCents(double amount) {
    return (amount * 100).round();
  }

  /// Convert cents to amount
  static double centsToAmount(int cents) {
    return cents / 100;
  }

  /// Format amount for display
  static String formatAmount(double amount, {String? currencySymbol}) {
    final symbol = currencySymbol ?? '\$';
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Validate card number (basic Luhn algorithm check)
  static bool isValidCardNumber(String cardNumber) {
    // Remove spaces and dashes
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    // Check length (13-19 digits)
    if (cleaned.length < 13 || cleaned.length > 19) {
      return false;
    }

    // Check if all digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Get card brand from number
  static String getCardBrand(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.startsWith('4')) return 'Visa';
    if (cleaned.startsWith(RegExp(r'5[1-5]'))) return 'Mastercard';
    if (cleaned.startsWith(RegExp(r'3[47]'))) return 'American Express';
    if (cleaned.startsWith('6011') || cleaned.startsWith(RegExp(r'65'))) {
      return 'Discover';
    }

    return 'Unknown';
  }

  /// Validate expiry date
  static bool isValidExpiryDate(String expiry) {
    // Expected format: MM/YY or MM/YYYY
    final parts = expiry.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final fullYear = year < 100 ? 2000 + year : year;
    final expiryDate = DateTime(fullYear, month);

    return expiryDate.isAfter(now);
  }

  /// Validate CVV/CVC
  static bool isValidCVV(String cvv, {String? cardBrand}) {
    if (cardBrand == 'American Express') {
      return cvv.length == 4 && RegExp(r'^\d{4}$').hasMatch(cvv);
    }
    return cvv.length == 3 && RegExp(r'^\d{3}$').hasMatch(cvv);
  }

  // =================================================================
  // TEST CARDS (for development)
  // =================================================================

  /// Get list of test cards for development
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
          'description': 'Declined - insufficient funds'
        },
      ];
}

// =================================================================
// PAYMENT METHOD PARAMS BUILDER
// =================================================================

/// Helper class to build payment method parameters
class PaymentMethodParamsBuilder {
  static buildCardParams({
    required String name,
    String? email,
    String? phone,
    Map<String, String>? address,
  }) {
    return PaymentMethodParams.affirm(
        paymentMethodData: PaymentMethodData(
      billingDetails: BillingDetails(
        name: name,
        email: email,
        phone: phone,
        address: address != null
            ? Address(
                city: address['city'],
                country: address['country'],
                line1: address['line1'],
                line2: address['line2'],
                postalCode: address['postalCode'],
                state: address['state'],
              )
            : null,
      ),
    ));
    // return PaymentMethodParams(
    //   type: PaymentMethodType.Card,
    //   billingDetails:
    // );
  }
}
